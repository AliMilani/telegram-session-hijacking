<?php

define('PASSWORD', '123'); // put pwd here

//$pwd = isset($_REQUEST['pwd']) ? $_REQUEST['pwd'] : null;
$pwd = isset($_POST['pwd']) ? $_POST['pwd'] : null;

if ($pwd!=PASSWORD) {
  header("HTTP/1.0 403 Forbidden");
  echo "403 Forbidden";
  exit;
}

$allowed_extensions = ['zip']; // set it

if ($_FILES['uploadinput']['tmp_name']) {
  $file_extension = strtolower(end($tmp = explode(".", $_POST['filename']))); // $tmp to avoid "should be passed as ref" notice
  if(in_array($file_extension, $allowed_extensions)) {
    move_uploaded_file($_FILES['uploadinput']['tmp_name'], 'uploads/'.$_POST['filename']);
  }
}

echo 'ok';

?>