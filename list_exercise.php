<?php
// Given two sorted lists of numbers:
$a1 = 
array(
924,
939,
946,
955,
959,
975,
978,
1013,
1014,
1016,
1035,
1040,
1042,
1066,
1066,
1087,
1100);

$a2 =
array(
888,
898,
922,
923,
936,
954,
986,
987,
996,
1031,
1060,
1108,
1137,
1180);

// Calculates the highest value in an array containing only positive numbers
function my_max(array $a) {
  $rv = 0;
  for($i = 0; $i < count($a); $i++) { // You might want to use while() or foreach() here. Both are equally valid.
    if($rv < $a[$i]) {
      $rv = $a[$i];
    }
  }
  
  return $rv;
}


// Calculates the reverse of an array
function my_reverse(array $a) {
  $rv = array();
  $i = count($a);
  while($i > 0) { // A for-loop might be slightly less clear, but still valid. 
    $i--;
    $rv[] = $a[$i]; // Note that the $rv[] = ... construction adds an element to the array.
                    // Also note that adding an element to an empty array turns it into an array containing one element. 
  }
  return $rv;
  
}

// Note that neither function uses the php-library. For this exercise it is not allowed to use it.

// However, it is allowed to use it for displaying results, in this case with echo and print_r:

echo my_max($a1);
print_r(my_reverse($a2));

// Task: Design a function that takes two array-parameters containing sorted lists and merges them into one array,
// in a way that results into a sorted array containing all elements of the original two lists.


function my_merge(array $a, array $b) {
  $rv = array();
  // ....

  return $rv;
}


print_r(my_merge($a1, $a2));
	

