use bytemuck::NoUninit;

use crate::camera::{Camera, CameraRaw};


pub struct Time {
    start: std::time::Instant,
    prev_frame: std::time::Instant,
    elapsed_frame: f32
}

impl Time {
    pub fn new() -> Self {
        Time {
            start: std::time::Instant::now(),
            prev_frame: std::time::Instant::now(),
            elapsed_frame: 0.0
        }
    }

    pub fn update(&mut self) {
        let now = std::time::Instant::now();
        self.elapsed_frame = (now - self.prev_frame).as_secs_f32();
        self.prev_frame = now;
    }

    pub fn elapsed(&self) -> f32 {
        self.start.elapsed().as_secs_f32()
    }
}

#[repr(C)]
#[derive(Clone, Copy, NoUninit)]
pub struct UniformRaw {
    camera: CameraRaw,
    time: f32,
    _padding: [f32; 3]
}

pub struct Uniform {
    time: Time,
    camera: Camera,
    buffer: wgpu::Buffer,
    pub bind_group_layout: wgpu::BindGroupLayout,
    pub bind_group: wgpu::BindGroup
}

impl Uniform {
    pub fn new(device: &wgpu::Device, camera: Camera) -> Self {
        let time = Time::new();

        let buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: None,
            size: std::mem::size_of::<UniformRaw>() as u64,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false
        });

        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: None,
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::all(),
                    ty: wgpu::BindingType::Buffer { 
                        ty: wgpu::BufferBindingType::Uniform, 
                        has_dynamic_offset: false, 
                        min_binding_size: None 
                    },
                    count: None
                }
            ]
        });

        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: None,
            layout: &bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: buffer.as_entire_binding()
                }
            ]
        });


        Uniform {
            time,
            buffer,
            bind_group,
            bind_group_layout,
            camera
        }
    }

    pub fn update(&mut self, queue: &wgpu::Queue) {
        self.time.update();
        self.camera.update(self.time.elapsed_frame);
        queue.write_buffer(&self.buffer, 0, bytemuck::cast_slice(&[self.as_raw()]));
    }

    pub fn as_raw(&self) -> UniformRaw {
        UniformRaw { 
            camera: self.camera.as_raw(), 
            time: self.time.elapsed(),
            _padding: [0.0, 0.0, 0.0]
        }
    }
}