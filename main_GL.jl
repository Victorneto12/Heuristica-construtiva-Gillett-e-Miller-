using DelimitedFiles,CSV,DataFrames,Plots
include("Gillet_Miller.jl") 
include("read_instance_SBRP.jl")
include("plot_results_GM.jl")

# Salvando o nome de todos os arquivos xpress na pasta instaces
pasta = "instances"
extensao = "xpress"
caminho_pasta = joinpath(pasta)
arquivos = readdir(caminho_pasta)
# Filtra os arquivos pela extensão desejada
arquivos_xpress = filter(x -> endswith(x, ".$extensao"), arquivos)

# Criando um dataframe para armazenar resultados das instâncias para cada um dos métodos
N_instance = Int[]
N_stop = Int[]
N_students = Int[]
cap = Int[]
Method = String[]
Zopt = Float64[]
Time = Float64[]
results = DataFrame(N_instance=N_instance, N_stop=N_stop, N_students=N_students, cap=cap, Method=Method, Zopt=Zopt, Time=Time)

global count = 0
for arquivo in arquivos_xpress
    global count += 1
    path_inst = "instances/"*arquivo
    # Leitura dos parâmetros da instância
    stop, q, C, w, coord_n, coord_q = read_instance(path_inst)

    # Incluindo a escola como sendo uma parada
    n = stop + 1

    # Calcular a matriz de distâncias
    c = zeros(Float64, n, n)
    for origem in 1:n
        for destino in 1:n
            c[origem, destino] = ((coord_n[origem, :X]-coord_n[destino, :X])^2 + (coord_n[origem, :Y]-coord_n[destino, :Y])^2)^0.5
        end
    end
    c = round.(c, digits=2)
    #println("A matriz de distancias é : ", c)  

    # conjunto de potenciais paradas
    V = Int[] 
    for j in 1:n
        push!(V,j)
    end
    #println("O vetor de potenciais paradas é: ", V)

    # Matriz que indica se existe aluno no percurso i,j 
    i = 1 # index da escola
    s_distance = zeros(n, q)

    # Calcular a matriz de alunos
    for student in 1:q
        for stop in 2:n
            d = ((coord_q[student, :X]-coord_n[stop, :X])^2 + (coord_q[student, :Y]-coord_n[stop, :Y])^2)^0.5
            s_distance[stop, student] = d
        end
    end
    #println("A matriz contendo os alunos é:  ", s_distance)

    s = zeros(n, q)
    for student in 1:q
        d_min = Inf
        stop_student = 1
        for stop in 2:n
            if s_distance[stop,student] < d_min && s_distance[stop,student] <= w
                stop_student = stop
                d_min = s_distance[stop,student]
            end
        end
        s[stop_student, student] = 1
    end 
    #println("A matriz contendo os alunos é:  ", s)

    X = Float64[]
    Y = Float64[]
    q2 = Int[]
    for stop in 1:n
        push!(X, coord_n[stop, :X])
        push!(Y, coord_n[stop, :Y])
        push!(q2, sum(s[stop,:]))
    end
    pontos = DataFrame(X=X, Y=Y, q=q2)

    t0=time_ns()
    zIP, best_route = Gillet_Miller(pontos, c, n, C)
    tzIP=(time_ns()-t0)/1e9
    println("A melhor rota é : ", best_route)
    println("O valor da função objetivo é: ", zIP)
    println("O tempo de processamento é: ", tzIP)

    # Salvando os resultados do SBRP
    
    namefile = "resultados/GM/SBRP_"*string(count)*"_s"*string(stop)*"_q"*string(q)*"_C"*string(C)*"_w"*string(w)*".txt"
    file = open(namefile, "w")
    println(file,"O valor da solução é: " *string(zIP))
    println(file, "O tempo de processamento é: "*string(tzIP))
    close(file)
    
    plot_result(count, n, q, C, w, s, coord_q, coord_n, best_route)
    
    #Salvando os resultados no dataframe
    result = Dict("N_instance" => count, "N_stop" => stop, "N_students" => q, "cap" => C, "Method" => "GM", "Zopt" => zIP, "Time" => tzIP)
    push!(results, result)

end

println(results)
CSV.write("resultados_GM.csv",results, delim=',')
println("Os resultados foram salvos com sucesso!")
