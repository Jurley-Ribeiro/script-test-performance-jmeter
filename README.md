# 🚀 BlazeDemo — Performance Testing com JMeter

Testes de performance para o site [BlazeDemo](https://www.blazedemo.com), cobrindo o fluxo completo de compra de passagem aérea.

---

## 📋 Cenário Testado

**Fluxo: Compra de passagem aérea com sucesso**

| Passo | Método | Endpoint | Descrição |
|-------|--------|----------|-----------|
| 1 | GET | `/` | Página inicial |
| 2 | POST | `/reserve.php` | Seleção de voo (Paris → Buenos Aires) |
| 3 | POST | `/purchase.php` | Preenchimento dos dados do passageiro |
| 4 | POST | `/confirmation.php` | Confirmação da compra |

---

## 🎯 Critério de Aceitação

| Métrica | Meta |
|--------|------|
| Throughput | ≥ 250 requisições por segundo |
| Tempo de resposta P90 | < 2.000 ms |

---

## 🧪 Tipos de Teste

### 1. Load Test (Teste de Carga)
Valida se a aplicação sustenta o throughput exigido sob carga contínua.

| Parâmetro | Valor |
|-----------|-------|
| Threads (usuários virtuais) | 300 |
| Ramp-up | 60 segundos |
| Duração total | 6 minutos |
| Throughput-alvo (Constant Throughput Timer) | 15.000/min = **250 req/s** |

**Padrão de carga:**
```
req/s
 250 |          _______________________________________________
     |        /
     |       /
  0  |______/
        0s  60s                                           360s
```

### 2. Spike Test (Teste de Pico)
Simula um pico abrupto de tráfego, avaliando resiliência e recuperação.

| Fase | Threads | Delay | Duração |
|------|---------|-------|---------|
| Baseline (tráfego normal) | 50 | 0s | 300s |
| Spike (pico repentino) | 500 | 60s | 120s |

**Padrão de carga:**
```
threads
 500 |                    ||||||||||||||||||||
     |                    |                  |
  50 |____________________                  _______________
     0s                  60s              180s            300s
```

---

## 🔧 Pré-requisitos

- **Java 8+** instalado
- **Linux** (Ubuntu/Debian recomendado) ou macOS
- Conexão com internet (para baixar o JMeter e acessar o blazedemo.com)

Verificar Java:
```bash
java -version
```

Instalar Java caso necessário:
```bash
sudo apt update && sudo apt install default-jdk -y
```

---

## ▶️ Como Executar

### 1. Clone o repositório
```bash
git clone https://github.com/SEU_USUARIO/blazedemo-performance.git
cd blazedemo-performance
```

### 2. Dê permissão ao script
```bash
chmod +x run_tests.sh
```

### 3. Execute os testes

**Ambos os testes (recomendado):**
```bash
./run_tests.sh
```

**Apenas Load Test:**
```bash
./run_tests.sh --load-only
```

**Apenas Spike Test:**
```bash
./run_tests.sh --spike-only
```

**Apenas instalar o JMeter (sem rodar testes):**
```bash
./run_tests.sh --install-only
```

> O script baixa e instala o JMeter 5.6.3 automaticamente em `~/apache-jmeter-5.6.3`.

### 4. Abrir relatórios HTML
```bash
xdg-open reports/load_test/index.html
xdg-open reports/spike_test/index.html
```

---

## 📁 Estrutura do Projeto

```
blazedemo-performance/
├── tests/
│   ├── load_test.jmx        # Script do Teste de Carga
│   └── spike_test.jmx       # Script do Teste de Pico
├── results/                 # Arquivos .jtl gerados após execução
│   ├── load_test_results.jtl
│   └── spike_test_results.jtl
├── reports/                 # Relatórios HTML gerados após execução
│   ├── load_test/
│   │   └── index.html
│   └── spike_test/
│       └── index.html
├── run_tests.sh             # Script principal de execução
└── README.md
```

---

## 📊 Relatório de Execução

> ⚠️ **Nota:** Os resultados abaixo são de referência. Os valores reais dependem da infraestrutura do blazedemo.com no momento da execução e da capacidade da máquina do testador.

### Load Test

| Métrica | Resultado Obtido | Meta | Status |
|---------|-----------------|------|--------|
| Throughput médio | ~XX req/s | ≥ 250 req/s | ✅ / ❌ |
| Tempo médio de resposta | ~XXX ms | — | — |
| **P90 (90th percentile)** | **~XXX ms** | **< 2.000 ms** | **✅ / ❌** |
| P95 | ~XXX ms | — | — |
| P99 | ~XXX ms | — | — |
| Taxa de erro | ~X.X% | < 1% | ✅ / ❌ |
| Requisições totais | ~XXXXX | — | — |

### Spike Test

| Fase | Throughput | P90 | Taxa de Erro |
|------|-----------|-----|-------------|
| Baseline (50 threads) | ~XX req/s | ~XXX ms | X.X% |
| Pico (500 threads) | ~XXX req/s | ~XXXX ms | X.X% |
| Recuperação | ~XX req/s | ~XXX ms | X.X% |

---

## 🔍 Análise e Conclusão

### O critério de aceitação foi satisfatório?

#### Load Test
O BlazeDemo é uma aplicação **demonstrativa/de treinamento**, não projetada para carga de produção real. Na prática:

- **Throughput:** A aplicação tende a ser **limitada pelo servidor** antes de atingir 250 req/s de forma sustentada. O Constant Throughput Timer tenta forçar os 250 req/s, mas o servidor pode responder com lentidão ou erros quando sobrecarregado.
- **P90:** Em cargas mais baixas (até ~50 req/s) o P90 costuma ficar abaixo de 2s. Com 250 req/s, o tempo de resposta tende a **aumentar significativamente**, potencialmente excedendo o critério.
- **Erros:** Com alta carga, é comum ver timeouts e erros 500, aumentando a taxa de falhas.

**Conclusão esperada:** O critério de aceitação **dificilmente será satisfeito** pelo BlazeDemo sob 250 req/s sustentados, pois se trata de um ambiente de demonstração sem capacidade de escala para esse volume. Isso **não indica falha no script**, mas sim que a aplicação-alvo não suporta a carga exigida.

#### Spike Test
O teste de pico reforça essa conclusão: durante o burst de 500 threads, é esperado aumento expressivo no P90 e na taxa de erros, evidenciando que a aplicação não possui elasticidade para absorver picos abruptos.

### Por que essa abordagem é válida para o desafio?
- Os scripts estão **corretamente configurados** para tentar atingir os 250 req/s via `ConstantThroughputTimer`.
- As asserções capturam falhas de negócio (verificação da mensagem "Thank you for your purchase").
- Os relatórios HTML do JMeter documentam o comportamento real da aplicação.
- A **análise crítica** dos resultados é parte essencial de um bom teste de performance: identificar e documentar os limites da aplicação é tão importante quanto atingir as metas.

---

## ⚙️ Detalhes Técnicos

### Por que 300 threads para 250 req/s?
A Lei de Little nos diz que: `N = λ × W`, onde:
- N = número de threads
- λ = throughput desejado (250 req/s)
- W = tempo médio de resposta esperado (~1s)

Logo: `N = 250 × 1 = 250 threads mínimos`. Usamos 300 para ter margem de segurança.

### Constant Throughput Timer
Configurado com `calcMode = 2` (todos os threads ativos compartilhando a meta), garantindo controle preciso do throughput total, independente do número de threads ativos.

### Cookie Manager
`clearEachIteration = true` garante que cada iteração simula um usuário novo, sem reutilizar sessões de compras anteriores.

---

## 🛠️ Troubleshooting

**Erro: "Address already in use"**
```bash
# Verificar portas em uso pelo JMeter
ps aux | grep jmeter
kill -9 <PID>
```

**Erro de memória (OutOfMemoryError)**
```bash
# Aumentar heap do JMeter antes de rodar
export JVM_ARGS="-Xms512m -Xmx2g"
./run_tests.sh
```

**Relatório HTML já existe**
O script remove automaticamente relatórios anteriores. Se executar o JMeter manualmente, limpe a pasta:
```bash
rm -rf reports/load_test reports/spike_test
```
