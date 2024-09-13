use std::sync::Arc;

use winit::{event::{Event, WindowEvent}, event_loop::EventLoop, window::WindowBuilder};

mod app_state;
mod uniform;
mod camera;
mod vertex;
mod texture;

fn main() {
   pollster::block_on(run());
}

async fn run() {
    let event_loop = EventLoop::new().unwrap();
    let window = WindowBuilder::new()
    .with_inner_size(winit::dpi::PhysicalSize::new(1600, 900))
    .build(&event_loop).unwrap();

    let window = Arc::new(window);
    let mut app_state = app_state::AppState::new(window.clone()).await;

    event_loop.run(move |event, elwt| {
        match event {
            Event::WindowEvent { 
                window_id, 
                event 
            } if window.id() == window_id => {
                match event {
                    WindowEvent::CloseRequested => {
                        elwt.exit();
                    },
                    WindowEvent::RedrawRequested => {
                        app_state.update();
                        match app_state.render() {
                            Err(wgpu::SurfaceError::OutOfMemory) => { elwt.exit() },
                            _ => {}
                        }
                    },
                    _ => {}
                }
            },
            Event::AboutToWait => {
                window.request_redraw();
            },
            _ => {}
        }
    }).unwrap();
}
