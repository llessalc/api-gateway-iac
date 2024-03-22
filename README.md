# api-gateway-iac CI/CD Terraform


## Criando conta no Terraform Cloud

- Acessar link [Terraform Cloud](https://app.terraform.io/session)
- Criar uma organização
- Criar um Workspace
  - Acessar **Variable** e definir duas novas variáveis de ambiente:
    - **AWS_ACCESS_KEY_ID**
    - **AWS_SECRET_ACCESS_KEY**
  - Usar os valores do **Key Pair** de sua conta AWS
- Acessar o **Account Setting** para gerar uma API ToKen

## Repositório Github 

- Após criado o Github Action acessar o repositório e criar uma nova Secrets  `TF_API_TOKEN`
  - Utilizar o token gerado no Terraform Cloud
- Ajustar no workflows o valor da variável de ambiente `TF_CLOUD_ORGANIZATION`. Esse deve ser a organização que foi gerada no Terraform Cloud

## Workflows

### Terraform Plan

- Nesse workflow vamos executar o Planejamento do Terraform e gerar um arquivo de output no Terraform Cloud
- Por fim sempre que um Pull Request for executando um comentário é criado automaticamente com o link do planejamento no Terraform 

### Terraform Apply

- Nesse workflow vamos executar o Planejamento e em seguida o Apply na cloud
- Esse será executado sempre que um Push for executado na branch Master, geralmente após o Merge do PR criado anteriormente na Develop