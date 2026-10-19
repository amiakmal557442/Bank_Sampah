import os
from PIL import Image, ImageDraw, ImageFilter

def create_rounded_mask(size, radius):
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), size], radius=radius, fill=255)
    return mask

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(base_dir, '..', 'website download app', 'assets')
    
    mobile_path = os.path.join(assets_dir, 'app-mobile-screen.png')
    desktop_path = os.path.join(assets_dir, 'app-desktop-screen.png')
    
    # Canvas tightly fitted around devices
    W, H = 1200, 720
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))

    # Ambient soft glow behind
    glow_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow_layer)
    gdraw.ellipse([200, 80, 1100, 620], fill=(16, 185, 129, 65))
    gdraw.ellipse([50, 200, 500, 680], fill=(6, 182, 212, 75))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(90))
    canvas = Image.alpha_composite(canvas, glow_layer)

    # 1. LAPTOP
    desk_img = Image.open(desktop_path).convert('RGBA')
    # Laptop screen: 820 x (820 * 483 / 1024) = 820 x 386
    screen_w = 820
    screen_h = int(screen_w * (desk_img.height / desk_img.width))
    desk_resized = desk_img.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    
    bezel_pad = 12
    bezel_top = 18
    bezel_bottom = 14
    lid_w = screen_w + (bezel_pad * 2)
    lid_h = screen_h + bezel_top + bezel_bottom
    
    lid = Image.new('RGBA', (lid_w, lid_h), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(lid)
    ldraw.rounded_rectangle([(0, 0), (lid_w, lid_h)], radius=16, fill=(30, 41, 59, 255), outline=(71, 85, 105, 255), width=2)
    
    # Camera
    cam_x = lid_w // 2
    ldraw.ellipse([cam_x - 3, 6, cam_x + 3, 12], fill=(15, 23, 42, 255), outline=(100, 116, 139, 255))
    
    # Screen with rounded mask
    smask = create_rounded_mask((screen_w, screen_h), 6)
    lid.paste(desk_resized, (bezel_pad, bezel_top), smask)
    
    # Base
    base_w = lid_w + 100
    base_h = 18
    base_deck = Image.new('RGBA', (base_w, base_h + 10), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(base_deck)
    bdraw.rounded_rectangle([(0, 0), (base_w, base_h)], radius=9, fill=(51, 65, 85, 255), outline=(71, 85, 105, 255), width=1)
    bdraw.line([(16, 1), (base_w - 16, 1)], fill=(148, 163, 184, 180), width=1)
    notch_w = 90
    notch_x = (base_w - notch_w) // 2
    bdraw.rounded_rectangle([(notch_x, 0), (notch_x + notch_w, 5)], radius=3, fill=(15, 23, 42, 255))

    lap_x = 240
    lap_y = 110

    # Laptop shadow
    lshadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ls_draw = ImageDraw.Draw(lshadow)
    ls_draw.ellipse([lap_x - 30, lap_y + lid_h - 10, lap_x + base_w + 30, lap_y + lid_h + 70], fill=(0, 0, 0, 160))
    lshadow = lshadow.filter(ImageFilter.GaussianBlur(30))
    canvas = Image.alpha_composite(canvas, lshadow)

    canvas.paste(lid, (lap_x + (base_w - lid_w) // 2, lap_y), lid)
    canvas.paste(base_deck, (lap_x, lap_y + lid_h - 4), base_deck)

    # 2. SMARTPHONE
    mob_img = Image.open(mobile_path).convert('RGBA')
    # Mobile screen: width 260px, height: 260 * (894 / 766) = 303px
    ps_w = 260
    ps_h = int(ps_w * (mob_img.height / mob_img.width))
    mob_resized = mob_img.resize((ps_w, ps_h), Image.Resampling.LANCZOS)

    ppad = 9
    ptop = 24
    pbottom = 20
    phone_w = ps_w + (ppad * 2)
    phone_h = ps_h + ptop + pbottom

    phone = Image.new('RGBA', (phone_w, phone_h), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(phone)
    pdraw.rounded_rectangle([(0, 0), (phone_w, phone_h)], radius=32, fill=(15, 23, 42, 255), outline=(16, 185, 129, 220), width=2)

    # Pill
    pill_w = 70
    pill_h = 10
    pill_x = (phone_w - pill_w) // 2
    pdraw.rounded_rectangle([(pill_x, 8), (pill_x + pill_w, 8 + pill_h)], radius=5, fill=(2, 6, 23, 255))

    pmask = create_rounded_mask((ps_w, ps_h), 20)
    phone.paste(mob_resized, (ppad, ptop), pmask)

    # Bottom bar
    pdraw.rounded_rectangle([(phone_w // 2 - 40, phone_h - 12), (phone_w // 2 + 40, phone_h - 9)], radius=2, fill=(255, 255, 255, 160))

    phone_x = 90
    phone_y = 260

    # Phone Shadow
    pshadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ps_draw = ImageDraw.Draw(pshadow)
    ps_draw.rounded_rectangle([(phone_x - 10, phone_y + 10), (phone_x + phone_w + 20, phone_y + phone_h + 30)], radius=40, fill=(0, 0, 0, 180))
    pshadow = pshadow.filter(ImageFilter.GaussianBlur(25))
    canvas = Image.alpha_composite(canvas, pshadow)

    canvas.paste(phone, (phone_x, phone_y), phone)

    out_png = os.path.join(assets_dir, 'hero-mockup.png')
    out_jpg = os.path.join(assets_dir, 'hero-mockup.jpg')
    canvas.save(out_png, 'PNG')

    # For JPG background
    bg = Image.new('RGB', (W, H), (12, 18, 20))
    bg.paste(canvas, (0, 0), canvas)
    bg.save(out_jpg, 'JPEG', quality=95)
    print("New tight composite generated!")

if __name__ == '__main__':
    main()
