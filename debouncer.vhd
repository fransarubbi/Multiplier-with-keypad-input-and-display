library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debouncer is
    Port ( col   : in  STD_LOGIC_VECTOR(3 downto 0);
	   clk   : in  STD_LOGIC;
           rst   : in  STD_LOGIC;
           row   : out  STD_LOGIC_VECTOR(3 downto 0);
           value : out  STD_LOGIC_VECTOR(3 downto 0);
	   rdy   : out STD_LOGIC);
end debouncer;

architecture Behavioral of debouncer is
	type state is (waiting, debouncing, reading);
   	signal state_present, state_future: state;
	
	-- Tecla
	signal key : std_logic_vector(3 downto 0);  -- Valor de la tecla
	
	-- Fila y Columna
	signal col_input : std_logic_vector(3 downto 0);        -- Columna de entrada
	signal row_one : std_logic_vector(15 downto 0);         -- Tiene toda la fila uno
	signal row_two : std_logic_vector(15 downto 0);         -- Tiene toda la fila dos
	signal row_three : std_logic_vector(15 downto 0);       -- Tiene toda la fila tres
	signal row_four : std_logic_vector(15 downto 0);        -- Tiene toda la fila cuatro
	signal row_definitive : std_logic_vector(15 downto 0);  -- Suma de las filas
	signal col_one : std_logic_vector(3 downto 0);          -- Tiene toda la columna uno
	signal col_two : std_logic_vector(3 downto 0);          -- Tiene toda la columna dos
	signal col_three : std_logic_vector(3 downto 0);        -- Tiene toda la columna tres
	signal col_four : std_logic_vector(3 downto 0);         -- Tiene toda la columna cuatro
	
	-- Shifter
	signal shifter_reg : std_logic_vector(3 downto 0);     -- Registro para escanear columnas
	signal shifter_input : std_logic_vector(3 downto 0);   -- Input del registro                    
	
	-- Controles
	signal C_load_cont : std_logic;    -- Control inicializar contador 80ms
	signal C_dec_cont : std_logic;     -- Control decrementar contador 80ms
	signal C_zero : std_logic;         -- Control contador 80ms en cero
	signal C_prescaler_zero : std_logic;  -- Control prescaler en cero
	signal C_shift_zero : std_logic;      -- Control registro shift en cero
	signal C_activate_shift : std_logic;  -- Control habilita registro shift
	signal col_sel_one : std_logic;       -- Control habilita columna uno
	signal col_sel_two : std_logic;       -- Control habilita columna dos
	signal col_sel_three : std_logic;     -- Control habilita columna tres
	signal col_sel_four : std_logic;      -- Control habilita columna cuatro
	
	-- Contadores
	signal CONT_prescaler_reg : std_logic_vector(15 downto 0);
	signal CONT_prescaler_input : std_logic_vector(15 downto 0);
	signal CONT_shift_reg : std_logic_vector(15 downto 0);
	signal CONT_shift_input : std_logic_vector(15 downto 0);
	signal CONT_reg : std_logic_vector(6 downto 0);
	signal CONT_input : std_logic_vector(6 downto 0);
	
	-- Matriz
	type keypad_matrix_type is array(0 to 3, 0 to 3) of std_logic_vector(3 downto 0);
	constant keypad_matrix : keypad_matrix_type := (
    ( "0001", "0010", "0011", "1010" ), 
    ( "0100", "0101", "0110", "1011" ),  
    ( "0111", "1000", "1001", "1100" ),  
    ( "1110", "0000", "1111", "1101" ));

   --+----------------------------+
	--|   1  |   2  |   3  |   A  |  
	--+----------------------------+
	--|   4  |   5  |   6  |   B  |  
	--+----------------------------+
	--|   7  |   8  |   9  |   C  |  
	--+----------------------------+
	--|   E  |   0  |   F  |   D  |  
	--+----------------------------+
	 
begin
	-- Control de bit de prioridad. El de mas a la izquierda es el mas prioritario
	col_input <= "1000" when col(3) = '1' else
					 "0100" when col(3) = '0' and col(2) = '1' else
					 "0010" when col(3) = '0' and col(2) = '0' and col(1) = '1' else
					 "0001" when col(3) = '0' and col(2) = '0' and col(1) = '0' and col(0) = '1' else
					 "0000";

	-- Contador prescaler de 50k -> 1ms
	C_prescaler_zero <= '1' when CONT_prescaler_reg = "0000000000000000" else '0';
	CONT_prescaler_input <= "1100001101010000" when C_prescaler_zero = '1' else 
									CONT_prescaler_reg - '1' when C_dec_cont = '1' else CONT_prescaler_reg;
	
	-- Contador shift de 50k -> 1ms
	C_shift_zero <= '1' when CONT_shift_reg = "0000000000000000" else '0';
	CONT_shift_input <= "1100001101010000" when C_shift_zero = '1' else 
								CONT_shift_reg - '1' when C_activate_shift = '1' else CONT_shift_reg;
	
	-- Contador de 80 ms
	C_zero <= '1' when CONT_reg = "0000000" else '0';
	CONT_input <= "1010000" when C_load_cont = '1' else
				      CONT_reg when C_dec_cont = '1' and C_prescaler_zero = '0' else
						CONT_reg - '1' when C_dec_cont = '1' and C_prescaler_zero = '1' else "0000000";


	col_sel_one <= '1' when col_input = "1000" else '0';   -- Habilita la columna 1
	col_sel_two <= '1' when col_input = "0100" else '0';   -- Habilita la columna 2
	col_sel_three <= '1' when col_input = "0010" else '0'; -- Habilita la columna 3
	col_sel_four <= '1' when col_input = "0001" else '0';  -- Habilita la columna 4

	-- Registro shift escaner
	shifter_input <= shifter_reg(0) & shifter_reg(3 downto 1) when 
				C_shift_zero = '1' else shifter_reg;
	
	row <= shifter_reg;  -- Activar la fila correspondiente

	gen_mux: for i in 0 to 3 generate   -- Se generan los multiplexores que seleccionan la fila
			row_one((15 - 4*i) downto (12 - 4*i)) <= keypad_matrix(0,i) when shifter_reg(3) = '1' else "0000";
			row_two((15 - 4*i) downto (12 - 4*i)) <= keypad_matrix(1,i) when shifter_reg(2) = '1' else "0000";
			row_three((15 - 4*i) downto (12 - 4*i)) <= keypad_matrix(2,i) when shifter_reg(1) = '1' else "0000";
			row_four((15 - 4*i) downto (12 - 4*i)) <= keypad_matrix(3,i) when shifter_reg(0) = '1' else "0000";
	end generate;
	
	row_definitive <= row_one or row_two or row_three or row_four;  -- Fila de la tecla presionada
	
	-- And y Or para filtrar la columna y obtener la tecla
	col_one <= row_definitive(15 downto 12) when col_sel_one = '1' else (others => '0');    -- Primera tecla de la fila
	col_two <= row_definitive(11 downto 8) when col_sel_two = '1' else (others => '0');     -- Segunda tecla de la fila
	col_three <= row_definitive(7 downto 4) when col_sel_three = '1' else (others => '0');  -- Tercera tecla de la fila
	col_four <= row_definitive(3 downto 0) when col_sel_four = '1' else (others => '0');    -- Cuarta tecla de la fila
	key <= col_one or col_two or col_three or col_four;  -- Tecla presionada
	
	deb: process(state_present, C_zero, col_input, key)
	begin
		C_dec_cont <= '0';
		C_load_cont <= '0';
		C_activate_shift <= '0';
		value <= "0000";
		rdy <= '0';
		state_future <= state_present;
		case state_present is
				when waiting =>
					C_activate_shift <= '1';
					C_load_cont <= '1';
					if col_input /= "0000" then
						state_future <= debouncing;
					end if;
					
				when debouncing =>
					C_activate_shift <= '0';
					if col_input /= "0000" then
						C_load_cont <= '0';
						C_dec_cont <= '1';
						if C_zero = '1' then
							state_future <= reading;
						else 
							state_future <= debouncing;
						end if;
					else
						state_future <= waiting;
					end if;
				
				when reading =>
					C_load_cont <= '0';
					C_dec_cont <= '0';
					value <= key;
					rdy <= '1';
					if col_input /= "0000" then
						state_future <= reading;
					else
						state_future <= waiting;
					end if;
		end case;
	end process deb;

	
	sec: process(clk, rst)
	begin
		if rst = '0' then
			CONT_prescaler_reg <= "1100001101010000";
			CONT_shift_reg <= "1100001101010000";
			CONT_reg <= "1010000";
			shifter_reg <= "1000";
			state_present <= waiting;
		elsif clk'event and clk = '1' then
			CONT_reg <= CONT_input;
			CONT_prescaler_reg <= CONT_prescaler_input;
			CONT_shift_reg <= CONT_shift_input;
			shifter_reg <= shifter_input;
			state_present <= state_future;
		end if;
	end process sec;
end Behavioral;
