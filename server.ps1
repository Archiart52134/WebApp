$port = if ($env:PORT) { [int]$env:PORT } else { 3000 }
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$port/"

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css"
  ".js"   = "application/javascript"
  ".json" = "application/json"
  ".png"  = "image/png"
  ".ico"  = "image/x-icon"
  ".svg"  = "image/svg+xml"
  ".woff2"= "font/woff2"
}

while ($listener.IsListening) {
  $ctx  = $listener.GetContext()
  $req  = $ctx.Request
  $res  = $ctx.Response
  $local = $req.Url.LocalPath
  if ($local -eq "/") { $local = "/index.html" }
  $file = Join-Path $root ($local.TrimStart("/").Replace("/","\\"))
  if (Test-Path $file -PathType Leaf) {
    $ext     = [System.IO.Path]::GetExtension($file).ToLower()
    $mime    = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { "application/octet-stream" }
    $bytes   = [System.IO.File]::ReadAllBytes($file)
    $res.ContentType     = $mime
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $res.StatusCode = 404
    $b = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
    $res.OutputStream.Write($b, 0, $b.Length)
  }
  $res.OutputStream.Close()
}
