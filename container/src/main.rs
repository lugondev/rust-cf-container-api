use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde_json::json;

async fn health() -> impl Responder {
    HttpResponse::Ok().json(json!({
        "status": "healthy",
        "service": "rust-container"
    }))
}

async fn ping() -> impl Responder {
    HttpResponse::Ok().body("pong")
}

async fn get_ip() -> impl Responder {
    match reqwest::get("https://ipinfo.io/json").await {
        Ok(response) => {
            match response.text().await {
                Ok(body) => {
                    HttpResponse::Ok()
                        .content_type("application/json")
                        .body(body)
                }
                Err(_) => {
                    HttpResponse::InternalServerError().json(json!({
                        "error": "Failed to read response"
                    }))
                }
            }
        }
        Err(_) => {
            HttpResponse::InternalServerError().json(json!({
                "error": "Failed to fetch IP info"
            }))
        }
    }
}

async fn index() -> impl Responder {
    HttpResponse::Ok().body("Hello from Rust on Cloudflare!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("Starting server on http://0.0.0.0:8080");
    
    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(index))
            .service(
                web::scope("/api")
                    .route("/health", web::get().to(health))
                    .route("/ping", web::get().to(ping))
                    .route("/ip", web::get().to(get_ip))
            )
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
