%% Entropic Coding and Compression
% This numerical tour studies source coding using entropic coders (Huffman and arithmetic).

perform_toolbox_installation('signal', 'general');

%% Source Coding and Entropy
% Entropic coding converts a vector |x| of integers into a binary stream
% |y|. Entropic coding exploits the
% redundancies in the statistical distribution of the entries of |x| to
% reduce as much as possible the size of |y|. The lower bound for the
% number of bits |p| of |y| is the Shannon bound |p=-sum_i
% h(i)*log2(h(i))|, where |h(i)| is the probability of apparition of
% symbol |i| in |x|.

%%
% Fist we generate a simple binary signal |x| so that 0 has a probability
% of appearance of |p|.

% probability of 0
p = 0.1;
% size
n = 512;
% signal, should be with token 1,2
x = (rand(n,1)>p)+1;

%%
% One can check the probabilities by computing the empirical histogram.

h = hist(x, [1 2]);
h = h/sum(h);
disp(strcat(['Empirical p=' num2str(h(1)) '.']));

%%
% We can compute the entropy of the distribution represented as a vector |h| of proability that should sum to 1.
% We take a |max| to avoid problem with 0 probabilties.

e = - sum( h .* log2( max(h,1e-20) ) );
disp( strcat(['Entropy=' num2str(e)]) );

%% Huffman Coding
% A Hufman code |C| associate with each symbol |i| in |{1,...,m}| a binary code |C{i}|
% whose length |length(C{i})| is as close as possible to the optimal bound
% |-log2(h(i))|, where |h(i)| is the probability of apparition of the
% symbol |i|.

%%
% We select a set of proabilities.

h = [.1 .15 .4 .15 .2];

%%
% The tree |T| cotainins the codes is generated by an iterative algorithm.
% The initial "tree" is a collection of empty trees, pointing to the symbols numbers.

m = length(h);
T = cell(0); % create an empty cell
for i=1:m
    T = cell_set(T,i,i);
end


%% 
% We build iteratively the Huffman tree
% by grouping together the two Trees that have the smallest probabilities.
% The merged tree has a probability which is the sums of the two selected
% probabilities.

% initial probability.
p = h;
% iterative merging of the leading probabilities
while length(p)>1   
    % sort in decaying order the probabilities
    [v,I] = sort(p);
    if v(1)>v(length(v))
        v = reverse(v); I = reverse(I);
    end 
    q = sum(v(1:2));
    t = cell_sub(T, I(1:2));
    % trimed tree
    T = cell_sub(T, I(3:length(I)) );
    p = v(3:length(v));
    % add a new node with the corresponding probability
    p(length(p)+1) = q;
    T = cell_set(T, length(p), t);
end


%%
% We display the computed tree.

clf;
plot_hufftree(T);


%% 
% Once the tree |T| is computed, one can compute the code |C{i}|
% associated to each symbol |i|. This requires to perform a deep first
% search in the tree and stop at each node. This is a little tricky to
% implement in Matlab, so you can use the function |huffman_gencode|.

C = huffman_gencode(T);
% display the code
for i=1:size(C,1)
    disp(strcat(['Code of token ' num2str(i) ' = ' num2str( cell_get(C,i) )]));
end

%% 
% We draw a vector |x| according to the distribution h

% size of the signal
n = 1024;
% randomization
x = rand_discr(h, n);
x = x(:);

%EXO
%% Implement the coding of the vector |x| to obtain a binary vector |y|, which corresponds to replacing
%% each sybmol |x(i)| by the code |C{x(i)}|.
y = [];
for i=1:length(x)
    y = [y cell_get(C, x(i))];
end
%EXO

%% 
% Compare the length of the code with the entropy bound.

e = - sum( h .* log2( max(h,1e-20) ) );
disp( strcat(['Entropy bound = ' num2str(n*e) '.']) );
disp( strcat(['Huffman code  = ' num2str(length(y)) '.']) );

%%
% Decoding is more complicated, since it requires parsing iteratively the
% tree |T|.

% initial pointer on the tree: on the root
t = cell_get(T,1);
% initial empty decoded stream
x1 = [];
% initial stream buffer
y1 = y;
while not(isempty(y1))
    % go down in the tree
    if y1(1)==0
        t = cell_get(t,1);
    else
        t = cell_get(t,2);
    end
    % remove the symbol from the stream buffer
    y1(1) = [];
    if not(iscell(t))
        % we are on a leaf of the tree: output symbol
        x1 = [x1 t];
        t = cell_get(T,1);
    end
end
x1 = x1(:);

%%
% We test if the decoding is correct.

err = norm(x-x1);
disp( strcat(['Error (should be 0)=' num2str(err) '.']) );

%% Huffman Block Coding
% A Huffman coder is inefficient because it can distribute only an integer
% number of bit per symbol. In particular, distribution where one of the
% symbol has a large probability are not well coded using a Huffman code.
% This can be aleviated by replacing the set of |m| symbols by |m^q|
% symbols obtained by packing the symbols by blocks of |q| (here we use |m=2| for a binary alphabet). This breaks
% symbols with large probability into many symbols with smaller proablity,
% thus approaching the Shannon entropy bound.

%% 
% Generate a binary vector with a high probability of having 1, so that the
% Huffman code is not very efficient (far from Shanon bound).

% proability of having 1
t = .12;
% probability distriution
h = [t; 1-t];
% generate signal
n = 4096*2;
x = (rand(n,1)>t)+1;


%% 
% For block of length |q=3|, create a new vector by coding each block 
% with an integer in |1,...,m^q=2^3|. The new length of the vector is
% |n1/q| where |n1=ceil(n/q)*q|.

% block size
q = 3;
% maximum token value
m = 2;
% new size
n1 = ceil(n/q)*q;
% new vector
x1 = x;
x1(length(x1)+1:n1) = 1;
x1 = reshape(x1,[q n1/q]);
[Y,X] = meshgrid(1:n1/q,0:q-1);
x1 = sum( (x1-1) .* (m.^X), 1 )' + 1;

%%
% We generate the probability table |H| of |x1| that represents the probability 
% of each new block symbols in |1,...,m^q|.

H = h; 
for i=1:q-1
    Hold = H;
    H = [];
    for i=1:length(h)
        H = [H; Hold*h(i)];
    end
end

%%
% A simpler way to compute this block-histogram is to use the Kronecker product.

H = h;
for i=1:q-1
    H = kron(H,h);
end

%EXO
%% For various values of block size |k|, Perform the hufman coding and compute the length of the code.
%% Compare with the entropy lower bound.
% entropy bound
e = -sum( log2(h).*h );
disp(['Entropy=' num2str(e) '.']);
qlist = 1:10;
err = [];
for q=qlist
    % lifting
    n1 = ceil(n/q)*q;
    x1 = x;
    x1(length(x1)+1:n1) = 1;
    x1 = reshape(x1,[q n1/q]);
    [Y,X] = meshgrid(1:n1/q,0:q-1);
    x1 = sum( (x1-1) .* (m.^X), 1 )' + 1;
    % Probability table
    H = h;
    for i=1:q-1
        H = kron(H,h);
    end
    % compute the tree
    T = compute_hufftree(H);
    % do the coding
    y = perform_huffcoding(x1,T,+1);
    % average number of bits
    e1 = length(y)/length(x);
    err(q) = e1-e;
    disp(['Huffman(block size ' num2str(q) ')=' num2str(e1)]);
end
clf;
plot(qlist,err, '.-');
set_label('q', 'entropy-code.length');
axis('tight');
%EXO

%% Arithmetic Coding
% A block coder is able to reach the Shannon bound, but requires the use of
% many symbols, thus making the coding process slow and memory intensive.
% A better alternative is the use of an arithmetic coder, that encode a
% stream using an interval.

%%
% Note : for this particular implementation of
% an arithmetic coder, the entries of this binary stream are packed by group of 8 bits so
% that each |y(i)| is in [0,255]. 

%%
% Generate a random binary signal.

% probability of 0
p = 0.1;
% size
n = 512;
% signal, should be with token 1,2
x = (rand(n,1)>p)+1;

%%
% The coding is performed using the function |perform_arith_fixed|.

% probability distribution
h = [p 1-p];
% coding
y = perform_arith_fixed(x,h);
% de-coding
x1 = perform_arith_fixed(y,h,n);
% see if everything is fine
disp(strcat(['Decoding error (should be 0)=' num2str(norm(x-x1)) '.']));

%EXO
%% Compare the average number of bits per symbol generated by the arithmetic coder
%% and the Shanon bound.
nb = length(y);
e1 = nb/n; % number of bit per symbol
% comparison with entropy bound
e = -sum( log2(h).*h ); % you have to use here the formula of the entropy
disp( strcat(['Entropy=' num2str(e, 3) ', arithmetic=' num2str(e1,3) '.']) );
%EXO

%%
% We can generate a more complex integer signal

n = 4096;
% this is an example of probability distribution
q = 10;
h = 1:q; h = h/sum(h); 
% draw according to the distribution h
x = rand_discr(h, n);
% check we have the correct distribution
h1 = hist(x, 1:q)/n;
clf;
subplot(2,1,1); 
bar(h); axis('tight');
set_graphic_sizes([], 20);
title('True distribution');
subplot(2,1,2);
bar(h1); axis('tight');
set_graphic_sizes([], 20);
title('Empirical distribution');

%EXO
%% Encode a signal with an increasing size |n|, and check how close the
%% generated signal coding rate |length(y)/n| becomes close to the optimal
%% Shannon bound.
e = -sum( h.*log2(h) );
% compute the differencial of coding for a varying length signal
err = []; 
slist = 4:12;
for i = 1:length(slist)
    n = 2^slist(i);
    x = rand_discr(h, n);
    % coding
    y = perform_arith_fixed(x(:),h);
    nb = length(y);
    e1 = nb/n; % number of bits per symbol
    err(i) = e1 - e;
end
clf;
plot(slist, err, '.-'); axis('tight');
set_label('log2(size)', '|entropy-nbr.bits|');
%EXO
