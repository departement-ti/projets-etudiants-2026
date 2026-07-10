using SR750.Listener;
using SR750.web.Components;
using Microsoft.Extensions.FileProviders;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddSingleton<ScanService>();
builder.Services.AddSingleton<AuthService>();
builder.Services.AddSingleton<ProjectService>();
builder.Services.AddSingleton<CameraService>();
builder.Services.AddSingleton<LanguageService>();

builder.Services.AddScoped(sp => new HttpClient());

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

// Serve camera screenshots
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(@"C:\DMC_Screenshots"),
    RequestPath = "/screenshots"
});

app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();