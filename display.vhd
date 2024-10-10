library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display is
    Port ( clk      : in  STD_LOGIC;
           rst      : in  STD_LOGIC;
			  show     : in  STD_LOGIC;                      -- Elige si mostramos la carga del teclado o el resultado
			  a        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Primer factor teclado
           b        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Segundo factor teclado
			  c        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Primer factor resultado
           d        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Segundo factor resultado
           selector : out STD_LOGIC_VECTOR(3 downto 0);   -- Activar digito
           digitos  : out STD_LOGIC_VECTOR(6 downto 0);   -- Activar leds
			  pd		  : out STD_LOGIC);                     -- Activar punto
end display;

architecture Behavioral of display is
	 -- Procedure para decodificar los 7 segmentos
	 procedure decodificador(signal x : in std_logic_vector(3 downto 0); 
									 signal digitos_out : out std_logic_vector(6 downto 0)) is
	 begin 
			case x is
            when "0000" => digitos_out <= "1111110"; -- 0
            when "0001" => digitos_out <= "0110000"; -- 1
            when "0010" => digitos_out <= "1101101"; -- 2
            when "0011" => digitos_out <= "1111001"; -- 3
            when "0100" => digitos_out <= "0110011"; -- 4
            when "0101" => digitos_out <= "1011011"; -- 5
            when "0110" => digitos_out <= "1011111"; -- 6
            when "0111" => digitos_out <= "1110000"; -- 7
            when "1000" => digitos_out <= "1111111"; -- 8
            when "1001" => digitos_out <= "1111011"; -- 9
            when "1010" => digitos_out <= "1111101"; -- A
            when "1011" => digitos_out <= "0011111"; -- B
            when "1100" => digitos_out <= "1001110"; -- C
            when "1101" => digitos_out <= "0111101"; -- D
            when "1110" => digitos_out <= "1101111"; -- E
            when "1111" => digitos_out <= "1000111"; -- F
            when others => digitos_out <= "0000000"; -- Apaga todos los segmentos en caso de error
        end case;
	 end procedure;
	
	-- Valores
	signal a_ls : std_logic_vector(3 downto 0);   -- 4 bits menos significativos de a
	signal a_ms : std_logic_vector(3 downto 0);   -- 4 bits mas significativos de a
	signal b_ls : std_logic_vector(3 downto 0);   -- 4 bits menos significativos de b
	signal b_ms : std_logic_vector(3 downto 0);   -- 4 bits mas significativos de b
	
	-- Controles
	signal C_timer_zero : std_logic;      -- Señal de control de que pasaron 2ms
	signal C_prescaler_zero : std_logic;  -- Señal de control de que pasaron 50k ciclos
	
	-- Shifter
	signal shifter_reg : std_logic_vector(3 downto 0);   -- Registro para escanear los digitos del display
	signal shifter_input : std_logic_vector(3 downto 0); 
	
	-- Contador
	signal CONT_prescaler_reg : std_logic_vector(15 downto 0) := "1100001101010000";  -- Prescaler
	signal CONT_prescaler_input : std_logic_vector(15 downto 0);
	signal CONT_timer_reg : std_logic_vector(1 downto 0);   -- Registro timer 
	signal CONT_timer_input : std_logic_vector(1 downto 0);   
	
	--     __a__
	--	   |		|
	--   f|     |b
	--    |__g__|
	--    |     |
	--	  e|		|c
	--	   |__d__|   .pd
	
begin
	pd <= '0';  -- Nunca activo el punto (no lo uso)
	
	-- Contador prescaler de 50k -> 1ms
	C_prescaler_zero <= '1' when CONT_prescaler_reg = "0000000000000000" else '0';
	CONT_prescaler_input <= "1100001101010000" when C_prescaler_zero = '1' else CONT_prescaler_reg - '1';

	-- Contador de 2ms
	C_timer_zero <= '1' when CONT_timer_reg = "00" else '0';
	CONT_timer_input <= "10" when C_timer_zero = '1' else 
								CONT_timer_reg - '1' when C_prescaler_zero = '1' else CONT_timer_reg;

	-- Registro shift escaner
	shifter_input <= shifter_reg(0) & shifter_reg(3 downto 1) when 
				C_timer_zero = '1' else shifter_reg;
	
	selector <= shifter_reg;   -- Activar el selector
	
	-- Si show = 1, se muestra el input, si es 0 se muestra el resultado
	a_ls <= a(3 downto 0) when show = '1' else c(3 downto 0);    -- Buffer de a_ls
	a_ms <= a(7 downto 4) when show = '1' else c(7 downto 4);    -- Buffer de a_ms
	b_ls <= b(3 downto 0) when show = '1' else d(3 downto 0);    -- Buffer de b_ls
	b_ms <= b(7 downto 4) when show = '1' else d(7 downto 4);    -- Buffer de b_ms
	
	dec:process(shifter_reg, a_ls, a_ms, b_ls, b_ms)    -- Process para decodificar la salida
	begin
		case shifter_reg is
			when "0111" => decodificador(b_ms, digitos);  -- Selecciona el dígito más a la izquierda
			when "1011" => decodificador(b_ls, digitos);  -- Selecciona el segundo dígito
			when "1101" => decodificador(a_ms, digitos);  -- Selecciona el tercer dígito
			when "1110" => decodificador(a_ls, digitos);  -- Selecciona el dígito más a la derecha
			when others => digitos <= "0000000"; -- Apaga todos los segmentos en caso de error
		end case;
	end process dec;
	
	sec:process(clk, rst)
	begin
		if rst = '0' then
			CONT_prescaler_reg <= "1100001101010000";
			shifter_reg <= "0111";
			CONT_timer_reg <= "10";
		elsif clk'event and clk = '1' then
			CONT_prescaler_reg <= CONT_prescaler_input;
			shifter_reg <= shifter_input;
			CONT_timer_reg <= CONT_timer_input;
		end if;
	end process sec;

end Behavioral;