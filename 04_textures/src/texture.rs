use project_root::get_project_root;
use wgpu::{naga::back::msl::sampler, ImageCopyTexture};



pub struct CubeMap {
    pub texture: wgpu::Texture,
    pub sampler: wgpu::Sampler,
    pub bind_group_layout: wgpu::BindGroupLayout,
    pub bind_group: wgpu::BindGroup
}

impl CubeMap {
    pub fn new(device: &wgpu::Device, queue: &wgpu::Queue) -> Self {
        let mut root = get_project_root().unwrap();
        root.push("assets");
        root.push("Cubemap");

        let faces_str = &[
            "yellowcloud_lf.jpg",
            "yellowcloud_rt.jpg",
            "yellowcloud_up.jpg",
            "yellowcloud_dn.jpg",
            "yellowcloud_ft.jpg",
            "yellowcloud_bk.jpg",
        ];

        let faces_img = faces_str.into_iter().enumerate().map(|(id,f)| {
            let mut root = root.clone();
            root.push(f);

            let mut image = image::open(root).unwrap();
            if id == 2 {
                image = image.rotate90();
            }

            if id == 3 {
                image = image.rotate270();
            }

            image.to_rgba8()
        }).collect::<Vec<_>>();

        let (width, height) = faces_img[0].dimensions();
        let texture_size = wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 6
        };

        let mut image = Vec::with_capacity((width * height * 6) as usize);
        for face in faces_img {
            image.extend_from_slice(&face);
        }

        let texture = device.create_texture(&wgpu::TextureDescriptor{
            label: None,
            size: texture_size,
            mip_level_count: 1,
            sample_count: 1,
            view_formats: &[],
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8UnormSrgb,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST
        });

        let texture_view = texture.create_view(&wgpu::TextureViewDescriptor{
            dimension: Some(wgpu::TextureViewDimension::Cube),
            ..Default::default()
        });

        let sampler = device.create_sampler(&wgpu::SamplerDescriptor{
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            ..Default::default()
        });

        queue.write_texture(
            wgpu::ImageCopyTexture{
                texture: &texture,
                origin: wgpu::Origin3d::ZERO,
                mip_level: 0,
                aspect: wgpu::TextureAspect::All
            }, 
            &image, 
            wgpu::ImageDataLayout {
                offset: 0,
                bytes_per_row: Some(width * 4),
                rows_per_image: Some(height)
            },
            texture_size
        );

        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor { 
            label: None, 
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture { 
                        sample_type: wgpu::TextureSampleType::Float { filterable: true }, 
                        view_dimension: wgpu::TextureViewDimension::Cube, 
                        multisampled: false 
                    },
                    count: None
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None
                },
            ] 
        });

        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: None, 
            layout: &bind_group_layout, 
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(&texture_view)
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(&sampler)
                }
            ] 
        });

        
        CubeMap {
            texture,
            sampler,
            bind_group_layout,
            bind_group
        }
    }
}