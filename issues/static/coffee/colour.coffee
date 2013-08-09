hex2rgb = (hex) ->
	if hex.charAt 0 == '#'
			hex = hex.substring 1, 7

	colour =
		r: parseInt (hex.substring 0, 2), 16
		g: parseInt (hex.substring 2, 4), 16
		b: parseInt (hex.substring 4, 6), 16

lumdiff = (c1, c2) ->
	l1 = (0.2126 * Math.pow c1.r / 255, 2.2) +
		 (0.7152 * Math.pow c1.g / 255, 2.2) +
		 (0.0722 * Math.pow c1.b / 255, 2.2)

	l2 = (0.2126 * Math.pow c2.r / 255, 2.2) +
		 (0.7152 * Math.pow c2.g / 255, 2.2) +
		 (0.0722 * Math.pow c2.b / 255, 2.2);

	if l1 > l2
		(l1 + 0.05) / (l2 + 0.05)
	else
		(l2 + 0.05) / (l1 + 0.05)

bestContrastingColour = (hex) ->
	black = '#000000'
	white = '#ffffff'

	bc = lumdiff (hex2rgb black), (hex2rgb hex)
	wc = lumdiff (hex2rgb white), (hex2rgb hex)

	if bc > wc then black else white
