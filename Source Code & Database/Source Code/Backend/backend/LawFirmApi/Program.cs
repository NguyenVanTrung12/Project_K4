using System.Text;
using LawFirmApi.Data;
using LawFirmApi.Hubs;
using LawFirmApi.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// =========================================================
// FILE UPLOAD LIMIT
// Cho phép upload tài liệu hồ sơ tối đa 50 MB
// =========================================================

const long MaxUploadSize = 50 * 1024 * 1024;

builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = MaxUploadSize;
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = MaxUploadSize;
});

// =========================================================
// DB CONTEXT - SQL SERVER
// =========================================================

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString(
            "DefaultConnection"
        )
    )
);

// =========================================================
// JWT AUTHENTICATION
// =========================================================

var jwtSection =
    builder.Configuration.GetSection("Jwt");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme =
        JwtBearerDefaults.AuthenticationScheme;

    options.DefaultChallengeScheme =
        JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters =
        new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer =
                jwtSection["Issuer"],

            ValidAudience =
                jwtSection["Audience"],

            IssuerSigningKey =
                new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(
                        jwtSection["Key"]!
                    )
                ),
        };

    // =====================================================
    // SIGNALR AUTHENTICATION
    // =====================================================

    options.Events =
        new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken =
                    context.Request.Query[
                        "access_token"
                    ];

                var path =
                    context.HttpContext.Request.Path;

                if (
                    !string.IsNullOrEmpty(
                        accessToken
                    )
                    &&
                    path.StartsWithSegments(
                        "/hubs"
                    )
                )
                {
                    context.Token =
                        accessToken;
                }

                return Task.CompletedTask;
            },
        };
});

// =========================================================
// AUTHORIZATION
// =========================================================

builder.Services.AddAuthorization();

// =========================================================
// TOKEN SERVICE
// =========================================================

builder.Services.AddScoped<
    ITokenService,
    TokenService
>();

// =========================================================
// SIGNALR
// =========================================================
//
// SignalR sử dụng JSON serializer riêng.
// Cấu hình camelCase để React / Flutter nhận đúng dữ liệu.
// =========================================================

builder.Services
    .AddSignalR()
    .AddJsonProtocol(options =>
    {
        options
            .PayloadSerializerOptions
            .PropertyNamingPolicy =
            System.Text.Json.JsonNamingPolicy
                .CamelCase;
    });

// =========================================================
// CORS
// =========================================================
//
// Cho phép:
// - React Admin
// - React Web
// - Flutter Web
// - Flutter Android
//
// Cấu hình này phù hợp với môi trường phát triển / đồ án.
// =========================================================

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "AllowClients",
        policy =>
        {
            policy
                .SetIsOriginAllowed(
                    _ => true
                )
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        }
    );
});

// =========================================================
// CONTROLLERS
// =========================================================

builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options
            .JsonSerializerOptions
            .ReferenceHandler =
            System.Text.Json.Serialization
                .ReferenceHandler
                .IgnoreCycles;
    });

// =========================================================
// SWAGGER
// =========================================================

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc(
        "v1",
        new OpenApiInfo
        {
            Title =
                "Themis & Cộng sự API",

            Version = "v1"
        }
    );

    // =====================================================
    // JWT AUTHORIZE BUTTON
    // =====================================================

    c.AddSecurityDefinition(
        "Bearer",
        new OpenApiSecurityScheme
        {
            Name =
                "Authorization",

            Type =
                SecuritySchemeType.ApiKey,

            Scheme =
                "Bearer",

            BearerFormat =
                "JWT",

            In =
                ParameterLocation.Header,

            Description =
                "Nhập: Bearer {token}",
        }
    );

    c.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference =
                        new OpenApiReference
                        {
                            Type =
                                ReferenceType
                                    .SecurityScheme,

                            Id =
                                "Bearer"
                        },
                },

                Array.Empty<string>()
            },
        }
    );
});

// =========================================================
// BUILD APPLICATION
// =========================================================

var app = builder.Build();

// =========================================================
// SWAGGER
// =========================================================

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();

    app.UseSwaggerUI();
}

// =========================================================
// HTTPS REDIRECTION
// =========================================================
//
// Không bật UseHttpsRedirection() vì Flutter Android
// đang gọi API HTTP trong môi trường local.
// =========================================================

// app.UseHttpsRedirection();

// =========================================================
// CORS
// =========================================================

app.UseCors("AllowClients");

// =========================================================
// STATIC FILES
// =========================================================
//
// Dùng để phục vụ các file trong:
// wwwroot/uploads
//
// Ví dụ:
// /uploads/cases/abc/file.pdf
// =========================================================

app.UseStaticFiles();

// =========================================================
// AUTHENTICATION
// =========================================================

app.UseAuthentication();

// =========================================================
// AUTHORIZATION
// =========================================================

app.UseAuthorization();

// =========================================================
// API CONTROLLERS
// =========================================================

app.MapControllers();

// =========================================================
// SIGNALR CHAT HUB
// =========================================================

app.MapHub<ChatHub>(
    "/hubs/chat"
);

// =========================================================
// RUN
// =========================================================

app.Run();