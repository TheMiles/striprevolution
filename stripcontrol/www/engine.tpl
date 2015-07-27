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
	    <a href="#nav-panel" data-icon="carat-l" data-rel="back" data-iconpos="notext">Back</a>
	    <a href="#nav-panel" data-icon="plus" data-rel="back" id="save" data-iconpos="notext">Add</a>
        </div>

        <div role="main" class="ui-content">

	  <p>Presets:</p>

	  <ul data-role="listview" data-inset="true">
	    <li>
              <a href="#">Camp fire</a>
              <a href="edit/1" class="ui-btn ui-icon-gear ui-btn-icon-left"></a>
            </li>
	    <li>
              <a href="#">Zauberwelt der Diamanten</a>
              <a href="edit/2" class="ui-btn ui-icon-gear ui-btn-icon-left"></a>
            </li>
	    <li>
              <a href="#">This must be underwater love</a>
              <a href="edit/3" class="ui-btn ui-icon-gear ui-btn-icon-left"></a>
            </li>
          </ul>

        </div>
 
        <div data-role="footer">
            <h4>&copy; 2015 by the LightMen Corporation.</h4>
        </div>
 
    </div>

</body>

</html>
