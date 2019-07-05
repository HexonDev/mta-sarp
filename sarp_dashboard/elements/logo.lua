local Elements = Dashboard.Elements

Elements.Logo = function(x, y, w, h)

    dxDrawRectangle(x, y, w, h, tocolor(24, 24, 24, 225))
    dxDrawImage(x + (w - respc(403 * 0.20)) * 0.5, y + respc(30), respc(403 * 0.20), respc(459 * 0.20), ":sarp_assets/images/sarplogo_big.png", 0, 0, 0, tocolor(50, 179, 239))
    

end