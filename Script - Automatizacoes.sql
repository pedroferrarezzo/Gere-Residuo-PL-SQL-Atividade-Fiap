-- PL/SQL (AUTOMATIZACOES)
    -- 1 AUTOMATIZACAO - Procedure que abre uma agenda de coleta | 2 AUTOMATIZACAO - Procedure que fecha uma agenda de coleta
        CREATE OR REPLACE PACKAGE PCK_GESTAO_RESIDUO_AUTOMATIZACOES 
            AS
                -- 1 AUTOMATIZACAO - Procedure que abre uma agenda de coleta
                PROCEDURE PRC_AGENDA_COLETA
                    (p_id_caminhao T_CAMINHAO.id%TYPE,
                    p_id_motorista T_MOTORISTA.id%TYPE,
                    p_id_bairro T_BAIRRO.id%TYPE,
                    p_tipo_residuo T_AGENDA.tipo_residuo%TYPE,
                    p_dia_semana T_AGENDA.dia_semana%TYPE);
                
                -- 2 AUTOMATIZACAO - Procedure que fecha uma agenda de coleta
                PROCEDURE PRC_TERMINA_AGENDA_COLETA
                    (p_id_agenda T_AGENDA.id%TYPE,
                    p_peso_coleta_kg T_AGENDA.peso_coleta_kg%TYPE);
            
            END PCK_GESTAO_RESIDUO_AUTOMATIZACOES;
            /
        
        CREATE OR REPLACE PACKAGE BODY PCK_GESTAO_RESIDUO_AUTOMATIZACOES
            AS
                -- 1 AUTOMATIZACAO - Procedure que abre uma agenda de coleta
                PROCEDURE PRC_AGENDA_COLETA
                            (p_id_caminhao T_CAMINHAO.id%TYPE,
                            p_id_motorista T_MOTORISTA.id%TYPE,
                            p_id_bairro T_BAIRRO.id%TYPE,
                            p_tipo_residuo T_AGENDA.tipo_residuo%TYPE,
                            p_dia_semana T_AGENDA.dia_semana%TYPE) 
                            
                            IS
                                -- VARIAVEIS - AGENDA COLETA
                                TYPE REC_AGENDA IS RECORD (
                                id_caminhao T_CAMINHAO.id%TYPE := p_id_caminhao,
                                id_motorista T_MOTORISTA.id%TYPE := p_id_motorista,
                                id_bairro T_BAIRRO.id%TYPE := p_id_bairro,
                                tipo_residuo T_AGENDA.tipo_residuo%TYPE := p_tipo_residuo,
                                dia_semana T_AGENDA.dia_semana%TYPE := p_dia_semana);
                                V_REC_AGENDA REC_AGENDA;
                                v_status_agenda_bairro T_BAIRRO.status_agenda%TYPE := PCK_GESTAO_RESIDUO_FUNCTIONS.FN_VERIFICA_AGENDA_BAIRRO(V_REC_AGENDA.id_bairro);
                                v_disp_motorista T_MOTORISTA.disponivel%TYPE := PCK_GESTAO_RESIDUO_FUNCTIONS.FN_VERIFICA_DISP_MOTORISTA(V_REC_AGENDA.id_motorista);
                                v_disp_caminhao T_CAMINHAO.disponivel%TYPE := PCK_GESTAO_RESIDUO_FUNCTIONS.FN_VERIFICA_DISP_CAMINHAO(V_REC_AGENDA.id_caminhao);
                                
                                -- VARIAVEIS - CRIA NOTIFICACAO PARA A COLETA
                                TYPE REC_NOTIFICACAO IS RECORD (
                                id_agenda T_AGENDA.id%TYPE,
                                nome_morador T_MORADOR.nome_morador%TYPE,
                                dia_semana T_NOTIFICACAO.dia_semana%TYPE := PCK_GESTAO_RESIDUO_FUNCTIONS.FN_RETORNA_DIA_SEMANA(p_dia_semana),
                                tipo_residuo T_AGENDA.tipo_residuo%TYPE := p_tipo_residuo,
                                email_morador T_MORADOR.email_morador%TYPE,
                                prc_coleta T_BAIRRO.prc_coleta%TYPE);
                                V_REC_NOTIFICACAO REC_NOTIFICACAO;
                                CURSOR C_T_NOTIFICACAO IS SELECT nome_morador, email_morador FROM T_MORADOR WHERE id_bairro = V_REC_AGENDA.id_bairro;
                            
                            BEGIN
                            
                                IF v_status_agenda_bairro = 1 AND v_disp_motorista = 1 AND v_disp_caminhao = 1 THEN
                                
                                    -- AGENDA A COLETA
                                    INSERT INTO T_AGENDA 
                                        (id_caminhao, id_motorista, id_bairro, dia_semana, tipo_residuo)
                                    VALUES
                                        (V_REC_AGENDA.id_caminhao, V_REC_AGENDA.id_motorista, V_REC_AGENDA.id_bairro, V_REC_AGENDA.dia_semana, V_REC_AGENDA.tipo_residuo);
                        
                                        -- ATUALIZA O STATUS DAS TABELAS ENVOLVIDAS NA ABERTURA DA AGENDA
                                        UPDATE T_BAIRRO SET status_agenda = 0 WHERE id = V_REC_AGENDA.id_bairro;
                                        UPDATE T_MOTORISTA SET disponivel = 0 WHERE id = V_REC_AGENDA.id_motorista;
                                        UPDATE T_CAMINHAO SET disponivel = 0 WHERE id = V_REC_AGENDA.id_caminhao;
                                    
                                    -- CRIA UMA NOTIFICACAO PARA A AGENDA
                                    -- ISEQ$$_1186809.CURRVAL = SEQUENCE gerada automaticamente pelo sistema para a tabela T_AGENDA
                                    SELECT ISEQ$$_1186809.CURRVAL INTO V_REC_NOTIFICACAO.id_agenda FROM DUAL;
                                    SELECT prc_coleta INTO V_REC_NOTIFICACAO.prc_coleta FROM T_BAIRRO WHERE id = V_REC_AGENDA.id_bairro;
                                    
                                    OPEN C_T_NOTIFICACAO;
                                    LOOP
                                    FETCH C_T_NOTIFICACAO INTO V_REC_NOTIFICACAO.nome_morador, V_REC_NOTIFICACAO.email_morador;
                                    EXIT WHEN C_T_NOTIFICACAO%NOTFOUND;
                                    INSERT INTO T_NOTIFICACAO
                                            (id_agenda, nome_morador, dia_semana, tipo_residuo, email_morador, prc_coleta_bairro)
                                        VALUES
                                            (V_REC_NOTIFICACAO.id_agenda, V_REC_NOTIFICACAO.nome_morador, V_REC_NOTIFICACAO.dia_semana, V_REC_NOTIFICACAO.tipo_residuo, V_REC_NOTIFICACAO.email_morador, V_REC_NOTIFICACAO.prc_coleta);
                                    END LOOP;
                                    CLOSE C_T_NOTIFICACAO;
                                
                                COMMIT;
                                
                                ELSE
                                    ROLLBACK;
                                    
                                    IF v_status_agenda_bairro = 0 THEN
                                        RAISE_APPLICATION_ERROR (-20001, 'O Bairro escolhido ja possui uma agenda');
                                        
                                    ELSIF v_disp_motorista = 0 THEN
                                        RAISE_APPLICATION_ERROR (-20002, 'O motorista escolhido ja foi alocado para uma agenda');
                                    
                                    ELSIF v_disp_caminhao = 0 THEN
                                        RAISE_APPLICATION_ERROR (-20003, 'O caminhao escolhido ja foi alocado para uma agenda');
                                    END IF;
                                END IF;
                                
                            END PRC_AGENDA_COLETA;
            
                -- 2 AUTOMATIZACAO - Procedure que fecha uma agenda de coleta
                PROCEDURE PRC_TERMINA_AGENDA_COLETA
                    (p_id_agenda T_AGENDA.id%TYPE,
                    p_peso_coleta_kg T_AGENDA.peso_coleta_kg%TYPE)
                    IS
                        v_id_bairro T_BAIRRO.id%TYPE;
                        v_id_caminhao T_CAMINHAO.id%TYPE;
                        v_id_motorista T_MOTORISTA.id%TYPE;
                        v_status_coleta T_AGENDA.status_coleta%TYPE;
                        v_prc_coleta T_BAIRRO.prc_coleta%TYPE;
                        
                    BEGIN
                    
                        SELECT status_coleta INTO v_status_coleta FROM T_AGENDA WHERE id = p_id_agenda;
                        
                        IF p_peso_coleta_kg <= 0 THEN
                                
                                RAISE_APPLICATION_ERROR (-20005, 'Peso da coleta e igual a 0 ou negativo');
                    
                        ELSIF v_status_coleta = 0 THEN
                    
                            SELECT id_bairro INTO v_id_bairro FROM T_AGENDA WHERE id = p_id_agenda;
                            SELECT id_motorista INTO v_id_motorista FROM T_AGENDA WHERE id = p_id_agenda;
                            SELECT id_caminhao INTO v_id_caminhao FROM T_AGENDA WHERE id = p_id_agenda;
                            v_prc_coleta := PCK_GESTAO_RESIDUO_FUNCTIONS.FN_CALCULA_PRC_COLETA(v_id_bairro, p_peso_coleta_kg);
                            
                            UPDATE T_BAIRRO SET status_agenda = 1 WHERE id = v_id_bairro;
                            UPDATE T_MOTORISTA SET disponivel = 1 WHERE id =  v_id_motorista;
                            UPDATE T_CAMINHAO SET disponivel = 1 WHERE id = v_id_caminhao;
                            UPDATE T_AGENDA SET 
                                peso_coleta_kg = p_peso_coleta_kg,
                                status_coleta = 1,
                                data_modificacao = DEFAULT
                            WHERE id = p_id_agenda;
                            UPDATE T_BAIRRO SET prc_coleta = v_prc_coleta WHERE id = v_id_bairro;
                            DELETE FROM T_NOTIFICACAO WHERE id_agenda = p_id_agenda;
                        
                            COMMIT;
                            
                        ELSE
                            ROLLBACK;
                            
                            IF v_status_coleta = 1 THEN
                                RAISE_APPLICATION_ERROR (-20004, 'A agenda em questao ja foi concluida.');
                            
                            END IF;
                        END IF;
                        
                    END PRC_TERMINA_AGENDA_COLETA;
            END PCK_GESTAO_RESIDUO_AUTOMATIZACOES;
            /  

        
    -- 3 AUTOMATIZACAO - Trigger que notifica moradores do bairro  via E-MAIL sobre agenda de coleta de lixo
        SET SERVEROUTPUT ON   
        CREATE OR REPLACE TRIGGER TR_ENVIA_EMAIL
                BEFORE INSERT ON T_NOTIFICACAO 
                FOR EACH ROW 
                BEGIN 
                    -- ENVIO DE E-MAIL
                /* 
                
                        UTL_MAIL.send(
                            sender      => 'postmaster_gere_residuo@gmail.com',
                            recipients  => ':NEW.email_morador',
                            subject     => 'Test Subject',
                            message     => 'Hello World!'
                        );
                */
                
                DBMS_OUTPUT.PUT_LINE('Ola ' || :NEW.nome_morador);
                DBMS_OUTPUT.PUT_LINE('Estamos te enviando este e-mail para avisar que ' || :NEW.dia_semana || ' havera coleta de lixo em seu bairro!');
                DBMS_OUTPUT.PUT_LINE('O tipo de residuo a ser coletado, e: ' || :NEW.tipo_residuo);
                DBMS_OUTPUT.PUT_LINE('Para que fique ligado, o percentual de coleta de lixo do seu bairro e de: ' || :NEW.prc_coleta_bairro || '%');
                
                END TR_ENVIA_EMAIL; 
                / 

    -- 4 AUTOMATIZACAO - Funcoes Diversas para construcao de procedures
        CREATE OR REPLACE PACKAGE PCK_GESTAO_RESIDUO_FUNCTIONS 
        AS
        
            FUNCTION FN_CALCULA_PRC_COLETA
            (p_id_bairro T_BAIRRO.id%TYPE,
            p_peso_coleta_kg T_AGENDA.peso_coleta_kg%TYPE)
            RETURN NUMBER;
            
            FUNCTION FN_VERIFICA_DISP_CAMINHAO (
                p_id_caminhao T_CAMINHAO.id%TYPE)
            RETURN NUMBER;
            
            FUNCTION FN_VERIFICA_DISP_MOTORISTA (
                p_id_motorista T_MOTORISTA.id%TYPE)
            RETURN NUMBER;
            
            FUNCTION FN_VERIFICA_AGENDA_BAIRRO (
                p_id_bairro T_BAIRRO.id%TYPE)
            RETURN NUMBER;
            
            FUNCTION FN_RETORNA_DIA_SEMANA (
                p_dia_semana T_AGENDA.dia_semana%TYPE)
            RETURN VARCHAR2;
        
        END PCK_GESTAO_RESIDUO_FUNCTIONS;
        /
        
        CREATE OR REPLACE PACKAGE BODY PCK_GESTAO_RESIDUO_FUNCTIONS
        AS
        
            FUNCTION FN_CALCULA_PRC_COLETA
                (p_id_bairro T_BAIRRO.id%TYPE,
                p_peso_coleta_kg T_AGENDA.peso_coleta_kg%TYPE)
                RETURN NUMBER
                
                IS
                    v_prc_coleta T_BAIRRO.prc_coleta%TYPE;
                    v_qtd_lixeiras T_BAIRRO.qtd_lixeiras%TYPE;
                    v_peso_m_lixeiras_kg T_BAIRRO.peso_m_lixeiras_kg%TYPE;
                BEGIN
                    SELECT peso_m_lixeiras_kg INTO v_peso_m_lixeiras_kg FROM T_BAIRRO WHERE id = p_id_bairro;
                    SELECT qtd_lixeiras INTO v_qtd_lixeiras FROM T_BAIRRO WHERE id = p_id_bairro;
                
                    v_prc_coleta := (p_peso_coleta_kg / (v_qtd_lixeiras*v_peso_m_lixeiras_kg))*100;
                    RETURN v_prc_coleta;
                
                END FN_CALCULA_PRC_COLETA;
                
            
            FUNCTION FN_VERIFICA_DISP_CAMINHAO (
                    p_id_caminhao T_CAMINHAO.id%TYPE)
                    RETURN NUMBER
                    
                IS 
                    v_disp_caminhao T_CAMINHAO.disponivel%TYPE;
                    
                BEGIN
                SELECT disponivel INTO v_disp_caminhao FROM T_CAMINHAO WHERE id = p_id_caminhao;
                RETURN v_disp_caminhao; 
                END FN_VERIFICA_DISP_CAMINHAO;
            
                
            FUNCTION FN_VERIFICA_DISP_MOTORISTA (
                    p_id_motorista T_MOTORISTA.id%TYPE)
                    RETURN NUMBER
                    
                IS 
                    v_disp_motorista T_MOTORISTA.disponivel%TYPE;
                
                BEGIN
                SELECT disponivel INTO v_disp_motorista FROM T_MOTORISTA WHERE id = p_id_motorista;
                RETURN v_disp_motorista; 
                END FN_VERIFICA_DISP_MOTORISTA;
                
            
            FUNCTION FN_VERIFICA_AGENDA_BAIRRO (
                    p_id_bairro T_BAIRRO.id%TYPE)
                    RETURN NUMBER
                    
                IS 
                    v_status_agenda_bairro T_BAIRRO.status_agenda%TYPE;
                
                BEGIN
                SELECT status_agenda INTO v_status_agenda_bairro FROM T_BAIRRO WHERE id = p_id_bairro;
                RETURN v_status_agenda_bairro; 
                END FN_VERIFICA_AGENDA_BAIRRO;
            

            FUNCTION FN_RETORNA_DIA_SEMANA (
                    p_dia_semana T_AGENDA.dia_semana%TYPE)
                    RETURN VARCHAR2
                    
                IS 
                BEGIN
                    CASE p_dia_semana
                        WHEN 1 THEN
                            RETURN 'Domingo';
                        WHEN 2 THEN
                            RETURN 'Segunda Feira';
                        WHEN 3 THEN
                            RETURN 'Terca Feira';
                        WHEN 4 THEN
                            RETURN 'Quarta Feira';
                        WHEN 5 THEN
                            RETURN 'Quinta Feira';
                        WHEN 6 THEN
                            RETURN 'Sexta Feira';
                        WHEN 7 THEN
                            RETURN 'Sabado';
                    END CASE;
                END FN_RETORNA_DIA_SEMANA;
            
        
        END PCK_GESTAO_RESIDUO_FUNCTIONS;
        /


-- DDL    
    --  CRIACAO TABELAS / CONSTRAINTS (NO FK)
        -- ####################################
        -- T_CAMINHAO 

        CREATE TABLE T_CAMINHAO (
            id NUMBER(5) GENERATED BY DEFAULT ON NULL AS IDENTITY,
            placa VARCHAR2(7) NOT NULL,
            ano_modelo DATE NOT NULL,
            marca VARCHAR2(20) NOT NULL,
            modelo VARCHAR2(20) NOT NULL,
            disponivel NUMBER(1) DEFAULT 1
        );

        ALTER TABLE T_CAMINHAO
            ADD CONSTRAINT PK_T_CAMINHAO PRIMARY KEY (id);

        ALTER TABLE T_CAMINHAO ADD CONSTRAINT UN_T_CAMINHAO_PLACA
            UNIQUE (placa);

        ALTER TABLE T_CAMINHAO ADD CONSTRAINT CK_T_CAMINHAO_PLACA
            CHECK(REGEXP_LIKE(placa,'^\d{7}$'));
            
        COMMENT ON COLUMN T_CAMINHAO.disponivel
            IS '1 = Caminhao disponivel, 0 = Caminhao alocado para alguma agenda';
              
        -- ####################################

        -- T_BAIRRO
        CREATE TABLE T_BAIRRO (
            id NUMBER(5) GENERATED BY DEFAULT ON NULL AS IDENTITY,
            nome_bairro VARCHAR2(30) NOT NULL,
            qtd_lixeiras NUMBER(5) NOT NULL,
            peso_m_lixeiras_kg NUMBER(5) NOT NULL,
            prc_coleta NUMBER(3) DEFAULT 100,
            status_agenda NUMBER(1) DEFAULT 1
        );

        ALTER TABLE T_BAIRRO
            ADD CONSTRAINT PK_T_BAIRRO PRIMARY KEY (id);

        ALTER TABLE T_BAIRRO ADD CONSTRAINT UN_T_BAIRRO
            UNIQUE (nome_bairro);
            
        COMMENT ON COLUMN T_BAIRRO.prc_coleta 
            IS 'Percentual de coleta de lixo no bairro';
            
        COMMENT ON COLUMN T_BAIRRO.status_agenda
            IS '1 = bairro sem agendamento de coleta, 0 = bairro agendado para coleta';

        -- ####################################

        -- T_NOTIFICACAO
        CREATE TABLE T_NOTIFICACAO (
            id NUMBER(5) GENERATED BY DEFAULT ON NULL AS IDENTITY,
            id_agenda NUMBER(5) NOT NULL,
            nome_morador VARCHAR2(20) NOT NULL,
            dia_semana VARCHAR2(20) NOT NULL,
            tipo_residuo VARCHAR2(10) NOT NULL,
            email_morador VARCHAR2(60) NOT NULL,
            prc_coleta_bairro NUMBER(3) NOT NULL
        );

        ALTER TABLE T_NOTIFICACAO
            ADD CONSTRAINT PK_T_NOTIFICACAO PRIMARY KEY (id);

        ALTER TABLE T_NOTIFICACAO ADD CONSTRAINT CK_T_NOTIFICACAO_EMAIL_MORADOR
            CHECK (email_morador LIKE '%_@__%.__%');
            
        -- ####################################

        -- T_AGENDA
        CREATE TABLE T_AGENDA (
            id NUMBER(5) GENERATED BY DEFAULT ON NULL AS IDENTITY,
            id_caminhao NUMBER(5) NOT NULL,
            id_motorista NUMBER(5) NOT NULL,
            id_bairro NUMBER(5) NOT NULL,
            dia_semana NUMBER(1) NOT NULL,
            tipo_residuo VARCHAR2(10) NOT NULL,
            data_modificacao TIMESTAMP DEFAULT SYSDATE,
            status_coleta NUMBER(1) DEFAULT 0,
            peso_coleta_kg NUMBER(10) DEFAULT 0
        );

        ALTER TABLE T_AGENDA
            ADD CONSTRAINT PK_T_AGENDA PRIMARY KEY (id);
            
        COMMENT ON COLUMN T_AGENDA.status_coleta 
            IS '1 = Coleta concluida, 0 = Coleta iniciada';

        -- ####################################

        -- T_MORADOR
        CREATE TABLE T_MORADOR (
            id NUMBER(5) GENERATED BY DEFAULT ON NULL AS IDENTITY,
            id_bairro NUMBER(5) NOT NULL,
            nome_morador VARCHAR2(30) NOT NULL,
            email_morador VARCHAR2(60) NOT NULL
        );

        ALTER TABLE T_MORADOR
            ADD CONSTRAINT PK_T_MORADOR PRIMARY KEY (id);

        ALTER TABLE T_MORADOR ADD CONSTRAINT UN_T_MORADOR_EMAIL_MORADOR
            UNIQUE (email_morador);

        ALTER TABLE T_MORADOR ADD CONSTRAINT CK_T_MORADOR_EMAIL_MORADOR
            CHECK (email_morador LIKE '%_@__%.__%');

        -- ####################################

        -- T_MOTORISTA
        CREATE TABLE T_MOTORISTA (
            id NUMBER(5) GENERATED BY DEFAULT ON NULL AS IDENTITY,
            nome_motorista VARCHAR2(30) NOT NULL,
            nr_cpf VARCHAR2(11) NOT NULL,
            nr_celular VARCHAR2(9) NOT NULL,
            nr_celular_ddd NUMBER(2) NOT NULL,
            nr_celular_ddi NUMBER(3) NOT NULL,
            disponivel NUMBER(1) DEFAULT 1
        );
        
        ALTER TABLE T_MOTORISTA
            ADD CONSTRAINT PK_T_MOTORISTA PRIMARY KEY (id);

        ALTER TABLE T_MOTORISTA ADD CONSTRAINT UN_T_MOTORISTA_NR_CPF
            UNIQUE (nr_cpf);

        ALTER TABLE T_MOTORISTA ADD CONSTRAINT CK_T_MOTORISTA_NR_CPF
            CHECK (REGEXP_LIKE(nr_cpf, '^\d{11}$'));

        ALTER TABLE T_MOTORISTA ADD CONSTRAINT UN_T_MOTORISTA_NR_CELULAR
            UNIQUE (nr_celular);
        
        ALTER TABLE T_MOTORISTA ADD CONSTRAINT CK_T_MOTORISTA_NR_CELULAR
            
            CHECK (REGEXP_LIKE(nr_celular,'^\d{9}$'));

        COMMENT ON COLUMN T_MOTORISTA.disponivel 
            IS '1 = Motorista disponivel, 0 = Motorista alocado para alguma agenda';
            
        -- ####################################

    -- Constraints FK
        ALTER TABLE T_AGENDA ADD CONSTRAINT FK_T_AGENDA_T_CAMINHAO FOREIGN KEY (id_caminhao) REFERENCES T_CAMINHAO (id);
        ALTER TABLE T_AGENDA ADD CONSTRAINT FK_T_AGENDA_T_MOTORISTA FOREIGN KEY (id_motorista) REFERENCES T_MOTORISTA (id);
        ALTER TABLE T_AGENDA ADD CONSTRAINT FK_T_AGENDA_T_BAIRRO FOREIGN KEY (id_bairro) REFERENCES T_BAIRRO (id);
        ALTER TABLE T_MORADOR ADD CONSTRAINT FK_T_MORADOR_T_BAIRRO FOREIGN KEY (id_bairro) REFERENCES T_BAIRRO (id);
        ALTER TABLE T_NOTIFICACAO ADD CONSTRAINT FK_T_NOTIFICACAO_T_AGENDA FOREIGN KEY (id_agenda) REFERENCES T_AGENDA (id);


-- DML
    -- T_BAIRRO
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Copacabana', 2, 10);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Ipanema', 4, 20);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Leblon', 6, 30);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Botafogo', 8, 40);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Lapa', 10, 50);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Santa Teresa', 12, 60);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Gloria', 14, 70);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Laranjeiras', 16, 80);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Flamengo', 18, 90);
    INSERT INTO T_BAIRRO (nome_bairro, qtd_lixeiras, peso_m_lixeiras_kg) VALUES ('Catete', 20, 100);
    
    -- T_MORADOR
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (1, 'Pedro Ferrarezzo', 'rm552309@fiap.com.br');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (2, 'Ana Santos', 'ana.santos@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (3, 'Pedro Oliveira', 'pedro.oliveira@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (4, 'Mariana Costa', 'mariana.costa@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (5, 'Lucas Rodrigues', 'lucas.rodrigues@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (6, 'Isabela Almeida', 'isabela.almeida@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (7, 'Rafael Lima', 'rafael.lima@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (7, 'Murilo Souza', 'msouuza@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (8, 'Fernanda Pereira', 'fernanda.pereira@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (9, 'Gustavo Souza', 'gustavo.souza@example.com');
    INSERT INTO T_MORADOR (id_bairro, nome_morador, email_morador) VALUES (10, 'Camila Santos', 'camila.santos@example.com');
    
    -- T_MOTORISTA
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Jo�o da Silva', '12345678901', '987654321', 11, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Maria Garra', '12345678902', '987654322', 12, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Pedro Silvestre', '12345678903', '987654323', 13, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Ana Antonnela', '12345678904', '987654324', 14, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Lucas Silmeira', '12345678905', '987654325', 15, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Isabela Leme', '12345678906', '987654326', 16, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Rafael Costa', '12345678907', '987654327', 17, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Fernanda Alcides', '12345678908', '987654328', 18, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Gustavo Marino', '12345678909', '987654329', 19, 55);
    INSERT INTO T_MOTORISTA (nome_motorista, nr_cpf, nr_celular, nr_celular_ddd, nr_celular_ddi) VALUES ('Camila Portugal', '23456789010', '976543210', 20, 55);
    
    -- T_CAMINHAO
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('1234567', TO_DATE('2004', 'YYYY'), 'Volvo', 'VNL 300');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('2345678', TO_DATE('2023', 'YYYY'), 'Scania', 'P 250');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('3456789', TO_DATE('2019', 'YYYY'), 'Mercedes-Benz', 'Actros 2646');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('4567890', TO_DATE('2021', 'YYYY'), 'Iveco', 'Tector 240E25');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('5678901', TO_DATE('2005', 'YYYY'), 'MAN', 'VW 23.230');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('6789012', TO_DATE('2018', 'YYYY'), 'DAF', 'XF105');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('7890123', TO_DATE('2007', 'YYYY'), 'Volvo', 'FH 540');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('8901234', TO_DATE('2024', 'YYYY'), 'Scania', 'R 450');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('9012345', TO_DATE('2016', 'YYYY'), 'Mercedes-Benz', 'Axor 3344');
    INSERT INTO T_CAMINHAO (placa, ano_modelo, marca, modelo) VALUES ('0123456', TO_DATE('2006', 'YYYY'), 'Iveco', 'Stralis 570');