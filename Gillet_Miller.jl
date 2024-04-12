# GILLET E MILLER 

function Gillet_Miller(pontos, c, N, Q) # primeiro ponto como escola
    # Calculando o ângulo 
    ang = zeros(Float64, N)
    C = Q
    for i in 2:N
        # Criando os vetores 
        delta_x = pontos[i, :X] - pontos[1, :X]
        delta_y = pontos[i, :Y] - pontos[1, :Y]

        # Calculando o ângulo 
        ang[i] = atan(delta_y,delta_x)
        if ang[i]<0
            ang[i]= 2*π + ang[i]
        end        
    end
    ordem_crescente = sortperm(ang)
    popfirst!(ordem_crescente) # remove a escola
    
    best_route = []
    best_solution = sum(c)

    for i in 1:N-1
        # Inicializando 
        route = [1]
        solution = c[1,1]

        # Organizando a rota 
        indices_i = []
        for j in i:length(ordem_crescente) 
            push!(indices_i, ordem_crescente[j])
        end
        for j in 1:i-1
            push!(indices_i, ordem_crescente[j])
        end
        
        n0 = 1
        C = Q
        # Começando
        for no in indices_i
            if C >= pontos[no, :q]
                push!(route, no)
                C = C - pontos[no, :q]
                solution = solution + c[n0, no]
            else
                # Voltando para a escola
                C = Q
                push!(route,1)
                solution = solution + c[n0,1]
                # Indo para o próximo nó
                push!(route,no)
                solution = solution + c[1,no]
                C = C - pontos[no, :q]
            end
            n0 = no 
        end
        # Voltando para a escola
        if n0 != 1 
            push!(route,1)
            solution = solution + c[n0,1]
        end
        #println(solution)   

        if solution<best_solution
            best_solution = solution
            best_route = route
        end
    end
    return best_solution, best_route
end