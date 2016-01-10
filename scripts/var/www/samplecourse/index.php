<h2>Course page for Sample Course. Adjust.</h2><ul>

</li>

<li><h4>Registered course participant login:</h4>
<form action="/logged.html" method="post" name="gateway">
<table><tr><td>Username:</td><td>

<input type="edit" name="login" value="">
</td></tr><tr><td>Password:</td><td>
<input type="password" name="pass" value="">
<input type="hidden" name="logingrp" value="samplecourse/">
</td></tr></table>

<input type="submit" value="GO TO USER PAGE">
</form>


<li>For questions about the course and the proof assistant, email <b>? (at sign) ? . ?</b></li>

<li><b>Disclaimer.</b> Please use Mozilla, Firefox, Galeon, Epiphany or Netscape >= 6. <br>
  With other browsers some or all features are missing.
</li>

<li><h4>Teacher login:</h4>
<form action="/cgi/admin.ml" method="post">
<table><tr><td>Username:</td><td>
<select name="login">
<option value="teacher1">Teacher's name</option>
</select>
</td></tr><tr><td>Password:</td><td>
<input type="password" name="pass" value="">
<input type="hidden" name="course" value="samplecourse">
</td></tr></table>


</ul>
