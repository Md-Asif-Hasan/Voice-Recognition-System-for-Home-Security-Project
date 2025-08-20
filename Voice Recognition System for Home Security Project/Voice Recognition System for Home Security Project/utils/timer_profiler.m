function timer_profiler(fhandle, nameStr)
if nargin < 2, nameStr = 'Block'; end
t = tic;
fhandle();
ms = toc(t)*1000;
fprintf('[%s] %.2f ms\n', nameStr, ms);
end
