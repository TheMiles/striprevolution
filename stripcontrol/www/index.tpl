<!DOCTYPE HTML>

<html>

<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1">

	<title>{{data["title"]}}</title>

	<script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
	<script src="https://code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.js"></script>
	<link rel="stylesheet" href="https://code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.css">

	<script src="/static/striprevolution.js"></script>
	<link rel="stylesheet" href="/static/striprevolution.css">
</head>

<body>

    <div data-role="page">
 
        <div data-role="header">
            <h1>{{data["title"]}}</h1>
        </div>

        <div role="main" class="ui-content">

	  <p>Chose an engine!</p>

	  <ul data-role="listview" data-inset="true">
	    <li><a href="/engine/droplets">Droplets</a></li>
          </ul>

        </div>
 
        <div data-role="footer">
            <h4>&copy; 2015 by the LightMen Corporation.</h4>
        </div>
 
    </div>

</body>

</html>
