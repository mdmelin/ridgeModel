function out = nancorr(X)
out = zeros(size(X,1),size(X,1));
for i = 1:size(X,1)
    parfor j = 1:size(X,1)
        out(i,j) = corr(X(i,:)',X(j,:)','rows','complete');
    end
end
end