<?php

// Solution to the exercise for checking whether a text contians a number between two user-supplied values



// skips chars until a number is found, and returns the value of that number.
// the skipped chars and the number are removed from the parameter
function get_next_number(&$string) {
  $rv = '';
  while(!ctype_digit($string{0}) and strlen($string) > 0) {
    $string = substr($string, 1);
  }
  while(ctype_digit($string{0}) and strlen($string) > 0) {
    $rv .= $string{0};
    $string = substr($string, 1);
  }

  return (int)$rv;
}


// Checks whether a string contains an integer-representing-substring which value is between $a and $b
function string_contains_number_between($string, $a, $b) {
  $found = false;
  while(!$found && strlen($string) > 0) {
    $n = get_next_number($string);
    $found = $a <= $n && $n <= $b;
  }
  return $found;
}

$string = file_get_contents('https://en.wikipedia.org/wiki/House_of_Plantagenet');

$a = 1337;
$b = 1453;


echo string_contains_number_between($string, $a, $b) ? 'YES' : 'NO';