function mpc = two_bus
mpc.version = '2';
mpc.baseMVA = 100;

% Self-authored teaching case: one slack bus, one PQ load, one series line.
mpc.bus = [
1 3 0 0 0 0 1 1.0 0 230 1 1.1 0.9;
2 1 100 50 0 0 1 1.0 0 230 1 1.1 0.9;
];

mpc.gen = [
1 0 0 300 -300 1.0 100 1 300 -300;
];

mpc.branch = [
1 2 0.01 0.1 0 0 0 0 0 0 1 -360 360;
];
end
