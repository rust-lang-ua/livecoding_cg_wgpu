use bytemuck::NoUninit;
use glam::{Vec2, Vec3, Vec4};
use project_root::get_project_root;
use wgpu::util::DeviceExt;


pub struct BufferGeometry {
    vertices: Vec<Vertex>,
    pub indices: Vec<u32>,
    pub vertex_buffer: wgpu::Buffer,
    pub index_buffer: wgpu::Buffer,
}

impl BufferGeometry {
    pub fn new(device: &wgpu::Device, vertices: Vec<Vertex>, indices: Vec<u32>) -> BufferGeometry {
        let vertices_raw: Vec<VertexRaw> = vertices.iter().map(|v| { v.as_raw() }).collect();

        let vertex_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: None,
            contents: bytemuck::cast_slice(vertices_raw.as_slice()),
            usage: wgpu::BufferUsages::VERTEX
        });

        let index_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: None,
            contents: bytemuck::cast_slice(indices.as_slice()),
            usage: wgpu::BufferUsages::INDEX
        });

        BufferGeometry {
            vertices,
            indices,
            vertex_buffer,
            index_buffer
        }
    }
}

pub struct Vertex {
    position: Vec3,
    normal: Vec3,
    uv: Vec2,
    color: Vec4
}

impl Vertex {
    pub fn as_raw(&self) -> VertexRaw {
        VertexRaw {
            position: self.position.to_array(),
            normal: self.normal.to_array(),
            uv: self.uv.to_array(),
            color: self.color.to_array()
        }
    }
}

#[repr(C)]
#[derive(Clone, Copy, NoUninit)]
pub struct VertexRaw {
    position: [f32; 3],
    normal: [f32; 3],
    uv: [f32; 2],
    color: [f32; 4]
}

impl Vertex {
    pub fn desc() -> wgpu::VertexBufferLayout<'static> {
        wgpu::VertexBufferLayout {
            array_stride: std::mem::size_of::<VertexRaw>() as u64,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    format: wgpu::VertexFormat::Float32x3,
                    offset: 0,
                    shader_location: 0
                },
                wgpu::VertexAttribute {
                    format: wgpu::VertexFormat::Float32x3,
                    offset: std::mem::size_of::<[f32; 3]>() as u64,
                    shader_location: 1
                },
                wgpu::VertexAttribute {
                    format: wgpu::VertexFormat::Float32x2,
                    offset: std::mem::size_of::<[f32; 6]>() as u64,
                    shader_location: 2
                },
                wgpu::VertexAttribute {
                    format: wgpu::VertexFormat::Float32x4,
                    offset: std::mem::size_of::<[f32; 8]>() as u64,
                    shader_location: 3
                },
            ]
        }
    }
}

pub fn load_model(device: &wgpu::Device) -> BufferGeometry {
    let mut root = get_project_root().unwrap();
    root.push("assets");
    root.push("bunny.obj");

    let (models, _materials) = tobj::load_obj(root, &tobj::GPU_LOAD_OPTIONS).unwrap();

    let model = &models[0];
    let mesh = &model.mesh;

    let mut vertices = Vec::new();
    for i in 0..mesh.positions.len() / 3 {
        let positions = &mesh.positions;
        let normals = &mesh.normals;
        let uvs = &mesh.texcoords;
        let position = Vec3::new(positions[i * 3 + 0], positions[i * 3 + 1], positions[i * 3 + 2]);
        let normal = Vec3::new(normals[i * 3 + 0], normals[i * 3 + 1], normals[i * 3 + 2]);
        let uv = Vec2::new(uvs[i * 2 + 0], uvs[i * 2 + 1]);

        vertices.push(Vertex {
            position,
            normal,
            uv,
            color: Vec4::new(1.0, 1.0, 1.0, 1.0)
        });
    }
    
    BufferGeometry::new(device, vertices, mesh.indices.clone())
}