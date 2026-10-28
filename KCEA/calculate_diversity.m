function diversity_matrix = calculate_diversity(Population)
    % 计算Population中所有个体之间的差异性
    % Population: 包含100个个体的结构体数组，每个个体有decs字段
    % 返回: 100x100的差异性矩阵
    
    n = length(Population); % 个体数量（应该是100）
    diversity_matrix = zeros(n, n); % 初始化差异性矩阵
    
    % 遍历所有个体对
    for i = 1:n
        for j = 1:n
            if i == j
                % 自己与自己的差异性为0
                diversity_matrix(i, j) = inf;
            else
                % 获取两个个体的决策向量
                vec1 = Population(i).decs{1};
                vec2 = Population(j).decs{1};
                
                % 计算差异性：对所有位置比较，不同则加1
                diff_count = sum(sum(vec1 ~= vec2)); % 注意这里用了两个sum
                diversity_matrix(i, j) = diff_count;
            end
        end
    end
% diversity_matrix = sum(diversity_matrix);