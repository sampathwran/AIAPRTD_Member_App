$source = 'C:\src\aiaprtd_member\android\app\src\main\res\drawable\my_bubble_icon.png'
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($source)
$bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(0, 0, $img.Width, $img.Height)
$g.SetClip($path)
$g.DrawImage($img, 0, 0)
$img.Dispose()
$bmp.Save($source, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$g.Dispose()
Write-Host "Rounded image saved!"
