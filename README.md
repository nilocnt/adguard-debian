# AdGuard CLI para Debian

Pacote Debian do [AdGuard CLI](https://adguard.com/en/adguard-cli/overview.html), configurado para executar como um serviço `systemd` de sistema.

## Características

- Instala o executável em `/usr/lib/adguard-cli/`.
- Disponibiliza o comando `adguard-cli` em `/usr/bin/adguard-cli`.
- Instala a unidade `adguard-cli.service`.
- Executa o serviço com o usuário e grupo de sistema `adguard`.
- Mantém os dados persistentes em `/var/lib/adguard-cli`.
- Migra automaticamente uma configuração existente de instalações anteriores em `/opt/adguard/.local/share/adguard-cli` ou `/home/*/.local/share/adguard-cli`.
- Remove o link simbólico legado da unidade em `/etc/systemd/system` quando ele aponta para a instalação antiga.

## Requisitos

- Debian ou derivado Debian com `systemd`.
- Arquitetura `amd64`.
- Permissões de `root` ou `sudo`.

O pacote declara `adduser` como dependência para criar o usuário e o grupo de sistema `adguard`.

## Instalação do pacote

Baixe ou gere o arquivo `.deb` e instale-o com:

```bash
sudo apt install ./adguard-debian_1.0.0_amd64.deb
```

O `postinst` cria o usuário `adguard`, prepara `/var/lib/adguard-cli` e habilita/reinicia o serviço quando o `systemd` está disponível.

Para iniciar e verificar o serviço:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now adguard-cli.service
systemctl status adguard-cli.service
```

Para consultar os logs:

```bash
sudo journalctl -u adguard-cli.service -f
```

## Configuração e dados

O serviço utiliza:

```text
Usuário: adguard
Grupo:   adguard
Dados:   /var/lib/adguard-cli
```

A unidade define `AG_CLI_DATA_PATH=/var/lib/adguard-cli`, garantindo que o serviço não dependa do diretório pessoal do usuário que instalou o pacote.

Para executar comandos administrativos do CLI, use:

```bash
sudo -u adguard env \
  HOME=/var/lib/adguard-cli \
  AG_CLI_DATA_PATH=/var/lib/adguard-cli \
  /usr/bin/adguard-cli --help
```

## Gerenciamento do serviço

```bash
sudo systemctl start adguard-cli.service
sudo systemctl stop adguard-cli.service
sudo systemctl restart adguard-cli.service
sudo systemctl enable adguard-cli.service
sudo systemctl disable adguard-cli.service
```

O serviço executa:

```text
/usr/bin/adguard-cli start --no-fork --log-to-file
```

O uso de `--no-fork` mantém o processo sob controle do `systemd`.

## Remoção

Para remover o pacote preservando os dados:

```bash
sudo apt remove adguard-debian
```

Para remover também os arquivos de configuração e dados:

```bash
sudo apt purge adguard-debian
sudo rm -rf /var/lib/adguard-cli
```

O diretório em `/var/lib` não deve ser apagado enquanto o serviço estiver em execução.

## Reconstrução do pacote

Este repositório contém uma árvore Debian já preparada para `dpkg-deb`. Para gerar o pacote:

```bash
dpkg-deb --build --root-owner-group . ../adguard-debian_1.0.0_amd64.deb
```

Depois, valide os metadados e o conteúdo:

```bash
dpkg-deb --info ../adguard-debian_1.0.0_amd64.deb
dpkg-deb --contents ../adguard-debian_1.0.0_amd64.deb
```

O arquivo `.deb` gerado não deve ser versionado no Git; ele é ignorado pelo `.gitignore`.

## Estrutura do pacote

```text
DEBIAN/
├── control
├── postinst
├── postrm
├── preinst
└── prerm
usr/
├── bin/
│   └── adguard-cli -> /usr/lib/adguard-cli/adguard-cli
└── lib/
    ├── adguard-cli/
    └── systemd/system/
        └── adguard-cli.service
```

## Licença

Consulte o arquivo [LICENSE](LICENSE) e os termos de redistribuição aplicáveis aos componentes do AdGuard CLI incluídos no pacote.
