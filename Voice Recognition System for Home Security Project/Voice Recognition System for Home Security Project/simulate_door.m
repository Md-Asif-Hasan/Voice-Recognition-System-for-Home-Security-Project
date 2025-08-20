function simulate_door(decision)
switch upper(decision)
    case 'ALLOW'
        fprintf('Door: UNLOCKED\n');
    otherwise
        fprintf('Door: LOCKED\n');
end
end
