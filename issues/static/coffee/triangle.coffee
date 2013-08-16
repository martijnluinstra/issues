class Turtle
	constructor: (@ctx, @x, @y, @color) ->
		@angle = 0.0;
	
	line: (length, color) ->
		@ctx.beginPath()
		@ctx.moveTo @x, @y

		@x += Math.cos(Math.PI * 2 * -@angle) * length
		@y += Math.sin(Math.PI * 2 * -@angle) * length

		@ctx.lineTo @x, @y

		@ctx.strokeStyle = color or @color
		@ctx.stroke()

		@ctx.closePath()
	
	move: (length) ->
		@x += Math.cos(Math.PI * 2 * -@angle) * length
		@y += Math.sin(Math.PI * 2 * -@angle) * length

		@ctx.moveTo @x, @y

	rotate: (angle) ->
		@angle = (@angle + angle) % 1.0

class Triangle
	playing: no

	requestFrame: window.requestAnimationFrame or \
				  window.webkitRequestAnimationFrame or \
				  window.mozRequestAnimationFrame

	constructor: (@canvas) ->
		@ctx = @canvas.getContext '2d'
		
		@animateCallback = (t) =>
			if @playing
				@drawStep t
				@requestFrame.call window, @animateCallback

		@resizeCallback = =>
			@canvas.width = @canvas.parentNode.offsetWidth * 2
			@canvas.height = @canvas.parentNode.offsetHeight * 2

	start: ->
		if @playing
			return

		@playing = yes
		@requestFrame.call window, @animateCallback
		window.addEventListener 'resize', @resizeCallback
		setTimeout @resizeCallback, 10

	stop: ->
		if not @playing
			return
		
		@playing = no
		window.removeEventListener 'resize', @resizeCallback

	smooth: (start, end, duration, t) ->
		state = Math.cos(Math.PI * ((t % duration) / duration - .5))
		start + (end - start) * state;

	draw: (x, y, r, d, w, n)->
		for i in [0..n]
			t = new Turtle(@ctx, x, y, '#ccc');

			t.rotate r + -1/4 + i/n
			t.move d

			# length of a side of the inner triangle
			a = 2 * Math.cos(.5/n * Math.PI) * d

			# length of the overshoot
			b = w / Math.cos(.5/n * Math.PI)

			# second line
			c = Math.tan(.5/n * Math.PI) * w + a + b + Math.tan(1/n * Math.PI) * w

			# third line
			e = Math.tan(1/n * Math.PI) * w + c - Math.tan(.5/n * Math.PI) * w

			# last line, the tail
			f = b;

			t.rotate 1/4
			t.rotate .5/n
			t.line a + b
			t.rotate 1/n
			t.line c
			t.rotate 1/n
			t.line e
			t.rotate .5/n
			t.line f
		
	drawStep: (t) ->
		r = @smooth 0, 1, 120000, t
		n = 3
		d = @smooth 0, @canvas.width / 8, 10000, t
		w = @smooth 10, @canvas.width / 8, 15000, t

		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
		@draw @canvas.width / 2, @canvas.height / 2, r, d, w, n

window.Triangle = Triangle