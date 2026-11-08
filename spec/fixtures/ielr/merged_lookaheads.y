%define lr.type ielr
%expect 0
%%
start: 'a' left 'd' | 'a' right 'f'
     | 'b' left 'e' | 'b' right 'f'
     | 'c' left 'd' | 'c' right 'e';
left: 'x';
right: 'x';
