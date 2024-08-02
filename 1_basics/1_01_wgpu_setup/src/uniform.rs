
pub struct Time {
    start: std::time::Instant
}

impl Time {
    pub fn new() -> Self {
        Time {
            start: std::time::Instant::now()
        }
    }

    pub fn elapsed(&self) -> f32 {
        self.start.elapsed().as_secs_f32()
    }
}

pub struct Uniform {
    time: Time,
    time_buffer: wgpu::Buffer,
    pub bind_group_layout: wgpu::BindGroupLayout,
    pub bind_group: wgpu::BindGroup
}

impl Uniform {
    pub fn new(device: &wgpu::Device) -> Self {
        let time = Time::new();

        let time_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: None,
            size: std::mem::size_of::<f32>() as u64,
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
                    resource: time_buffer.as_entire_binding()
                }
            ]
        });


        Uniform {
            time,
            time_buffer,
            bind_group,
            bind_group_layout
        }
    }

    pub fn update(&self, queue: &wgpu::Queue) {
        queue.write_buffer(&self.time_buffer, 0, bytemuck::cast_slice(&[self.time.elapsed()]));
    }
}