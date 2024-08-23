use bytemuck::NoUninit;
use glam::{Mat4, Vec3};


pub struct Camera {
    fov: f32,
    aspect_ratio: f32,
    near: f32,
    far: f32,
    position: Vec3,
    up: Vec3,
    direction: Vec3
}

impl Camera {
    pub fn new(fov: f32, aspect_ratio: f32, near: f32, far: f32, position: Vec3, up: Vec3, direction: Vec3) -> Self {
        Camera {
            fov,
            aspect_ratio,
            near,
            far,
            position,
            up,
            direction
        }
    }

    pub fn view_matrix(&self) -> Mat4 {
        Mat4::look_to_rh(self.position, self.direction, self.up)
    }

    pub fn perspective_matrix(&self) -> Mat4 {
        Mat4::perspective_rh(f32::to_radians(self.fov), self.aspect_ratio, self.near, self.far)
    }

    pub fn update(&mut self, time: f32) {
        let rotation_matrix = Mat4::from_rotation_y(time * 0.5);
        self.position = rotation_matrix.transform_vector3(self.position);
        self.direction = Vec3::new(0.0, 0.0, 0.0) - self.position;
    }

    pub fn as_raw(&self) -> CameraRaw {
        CameraRaw { 
            view_matrix: self.view_matrix().to_cols_array(), 
            perspective_matrix: self.perspective_matrix().to_cols_array() 
        }
    }
}

#[repr(C)]
#[derive(Clone, Copy, NoUninit)]
pub struct CameraRaw {
    view_matrix: [f32; 16],
    perspective_matrix: [f32; 16]
}