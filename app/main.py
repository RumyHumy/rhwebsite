from fastapi import FastAPI, Request
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from pathlib import Path

app = FastAPI()

# Mount static files from ~/rhwebsite/static
static_dir = Path.home() / "rhwebsite/static"
app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")

# Redirect HTTP to HTTPS
@app.get("/{path:path}", include_in_schema=False)
async def redirect_to_https(request: Request, path: str):
    if request.url.scheme != "https":
        return RedirectResponse(url=f"https://{request.url.hostname}{request.url.path}")
    return await app.default_router(request)
