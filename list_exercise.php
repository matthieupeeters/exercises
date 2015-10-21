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
1066,
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



// Finds the smallest value that is present in two *sorted* arrays
function find_first_match(array $a, array $b) {
  $i = 0;
  $j = 0;
  while($j < count($a) && $j < count($b) && $a[$i] != $b[$j]) { // Note that the check whether $i and $j are in range...
    // ...has to come before whe use $a[$i] or $b[$j]. 
    // Also note that when we check something in the condition of a while-statement, it is true in the whole body,
    // unless the checked values are changed. 
    if($a[$i] < $b[$j]) {
      $i++;  // The sought value has to be bigger than $a[$i], and thus come after $a[$i]
    } else { // $a[$i] > $b[$j] since where are in a while loop that demands $a[$i] != $b[$j]
      $j++;  // The sought value has to be bigger than $b[$j]. 
    }
  }
  if ($j < count($a) && $j < count($b)) { // This means that the condition on which the while-loop ended was $a[$i] != $b[$j]..
    // ..That means that $a[$i] == $b[$i] and we have found our equal value. We don't check whether $a[$i] == $b[$j] because..
    // ..if $i >= count($a) or $j >= count($b) we would try to address values that are not part of the array. Resulting in..
    // ..unpredictable behaviour.
    return $a[$i];
  } else { // This means that $i >= count($a) or $j >= count($b), so we reached the end of an array without finding a match.
    throw new Exception('Value not found.');    
  }
}


echo find_first_match($a1, $a2);



// Task: Design a function that takes two array-parameters containing sorted lists and merges them into one array,
// in a way that results into a sorted array containing all elements of the original two lists.


function my_merge(array $a, array $b) {
  $rv = array();
  // ....

  return $rv;
}


print_r(my_merge($a1, $a2));
	

