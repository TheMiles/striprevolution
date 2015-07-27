$(document).ready(function() {

	function sendData() {
		$.ajax({
			type: 'POST',
			url: '/request',
			data: JSON.stringify($('#data').serializeArray()),
			contentType: "application/json",
			dataType: "json",
			success: function(result) {},
			error: function(result) {console.log("error", result);}
		});
    	}

	$('.trigger').on('slidestop', function(event) {
		sendData();
	});

	console.log($('#hue-range').children('.ui-rangeslider-sliders'));

	$('#hue-range').find('.ui-slider-track').css({
	        'background': 'url("/static/graphics/hue-gradient.svg") repeat-x',
		'background-position': 'center',
		'background-size': '105%'
	});

	console.log($('#hue-range').find('.ui-slider-bg.ui-btn-active'));

	$('#hue-range').find('.ui-slider-bg.ui-btn-active').css({
                'background-color': 'transparent',
		'border': '7px solid #38c',
	        'height': '15px',
	        'margin-top': '-7px'
	});

});