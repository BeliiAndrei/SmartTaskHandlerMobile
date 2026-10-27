// PAM backend template - .NET (Minimal API) port.
//
// Start:  dotnet run
// Env:    PORT (default 8080), JWT_SECRET (default dev-secret-change-me)

using PamBackend;

var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";

var builder = WebApplication.CreateBuilder(args);

// Permissive CORS so a Flutter *web* build can call the API during the labs.
builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

// Make binding failures (malformed JSON body, unparseable parameters) THROW
// instead of writing a bare 400 - our error middleware then answers with the
// contract shape {"error":{"code":"VALIDATION_ERROR",...}}.
builder.Services.Configure<RouteHandlerOptions>(o => o.ThrowOnBadRequest = true);

var app = builder.Build();

app.Use(Errors.HandleExceptions); // must be first, so it wraps everything
app.UseCors();
// No UseHttpsRedirection() on purpose: plain HTTP for local lab use.

Db.Init("app.db");          // creates app.db + schema on first start
Files.InitStorage("uploads"); // creates uploads/ on first start

app.MapGet("/health", () => Results.Json(new { status = "ok" }));
app.MapPost("/auth/register", Auth.Register);
app.MapPost("/auth/login", Auth.Login);
app.MapGet("/me", Auth.Me).AddEndpointFilter(Auth.RequireAuth);

// Notes: the example entity. Register your own routes the same way.
var notes = app.MapGroup("/notes").AddEndpointFilter(Auth.RequireAuth);
notes.MapGet("", Notes.List);
notes.MapPost("", Notes.Create);
notes.MapGet("/{id:long}", Notes.GetOne);
notes.MapPut("/{id:long}", Notes.Update);
notes.MapDelete("/{id:long}", Notes.Delete);

app.MapPost("/files", Files.Upload).AddEndpointFilter(Auth.RequireAuth);
app.MapGet("/files/{id:long}", Files.Download); // public on purpose (images by URL)

// Any unknown route -> 404 in the standard error shape.
app.MapFallback(() => Errors.NotFound("Route not found"));

// The PORT env variable wins over everything else (ASPNETCORE_URLS,
// launchSettings.json) - passing the URL here overrides any configured address.
app.Run($"http://0.0.0.0:{port}");
