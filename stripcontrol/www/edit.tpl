<!DOCTYPE HTML>

<html>

<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1">

	<title>{{data["title"]}}</title>

	<script src="/static/jquery/src/jquery.js"></script>
	<script src="/static/jquery-mobile/js/jquery.mobile.js"></script>
	<link rel="stylesheet" href="/static/jquery-mobile/css/themes/default/jquery.mobile.css">

	<script src="/static/striprevolution.js"></script>
	<link rel="stylesheet" href="/static/striprevolution.css">
</head>

<body>

    <div data-role="page">
 
        <div data-role="header">
            <h1>{{data["title"]}}</h1>
	    <a href="#nav-panel" data-icon="carat-l" data-rel="back" data-iconpos="notext">Back</a>
	    <a href="#nav-panel" data-icon="check" data-rel="back" id="save" data-iconpos="notext">Save</a>
        </div>
 
        <div data-role="content">

	<form id="data">

	  <label for="name">Preset name:</label>
	  <input type="text" id="name">

	  <div data-role="rangeslider" id="hue-range">
	    <label for="hue-min">Hue range:</label>
	    <input type="range" name="hue-min" id="hue-min" class="trigger" min="0" max="100" value="0" />
	    <label for="hue-max">Hue range:</label>
	    <input type="range" name="hue-max" id="hue-max" class="trigger" min="0" max="100" value="100" />
	  </div>

	  <label for="hue-shift">Hue shift:</label>
	  <input type="range" name="hue-shift" id="hue-shift" class="trigger" min="0" max="100" value="0">

	  <label for="saturation">Saturation:</label>
	  <input type="range" name="saturation" id="saturation" class="trigger" min="0" max="100" value="0">
	
	  <label for="probability">Probability:</label>
	  <input type="range" name="probability" id="probability" class="trigger" min="0" max="100" value="50">

	</form>

        </div>
 
        <div data-role="footer">
            <h4>&copy; 2015 by the LightMen Corporation.</h4>
        </div>
 
    </div>

</body>

</html>
