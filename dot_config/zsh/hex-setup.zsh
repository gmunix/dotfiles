hex-setup(){
  bw list items --search hex | jq '.[0].notes' | echo
}
