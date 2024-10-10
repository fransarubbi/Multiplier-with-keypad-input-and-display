library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.conversor.all;

entity all_components is
    Port (col      : in  STD_LOGIC_VECTOR(3 downto 0);
          clk      : in  STD_LOGIC;
          rst      : in  STD_LOGIC;
			 row      : out STD_LOGIC_VECTOR(3 downto 0);
          selector : out STD_LOGIC_VECTOR(3 downto 0);  
          digitos  : out STD_LOGIC_VECTOR(6 downto 0);
          pd       : out STD_LOGIC);
end all_components;

architecture Behavioral of all_components is
    -- Declaración de señales internas
    signal value_signal        : STD_LOGIC_VECTOR(3 downto 0);
    signal rdy_signal          : STD_LOGIC;
    signal first_factor_signal : STD_LOGIC_VECTOR(7 downto 0);
    signal second_factor_signal: STD_LOGIC_VECTOR(7 downto 0);
	 signal finish_signal       : STD_LOGIC;
    signal plot_signal         : STD_LOGIC;
    signal res_ls_signal       : STD_LOGIC_VECTOR(7 downto 0);
    signal res_ms_signal       : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Instanciación de los componentes
    component debouncer
        Port ( col   : in  STD_LOGIC_VECTOR(3 downto 0);
               clk   : in  STD_LOGIC;
               rst   : in  STD_LOGIC;
               row   : out STD_LOGIC_VECTOR(3 downto 0);
               value : out STD_LOGIC_VECTOR(3 downto 0);
               rdy   : out STD_LOGIC);
    end component;

    component admin
        Port ( clk           : in  STD_LOGIC;
               rst           : in  STD_LOGIC;
               ready         : in  STD_LOGIC;
               value_in      : in  STD_LOGIC_VECTOR(3 downto 0);
					finish        : out STD_LOGIC;
               plot          : out STD_LOGIC;
               first_factor  : out STD_LOGIC_VECTOR(7 downto 0);
               second_factor : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component multiplicador
        generic(N : integer := 8);
        port(
				activate : in  std_logic;
            A, B     : in  STD_LOGIC_VECTOR(N-1 downto 0);
            rst, clk : in  STD_LOGIC;
            res_ls   : out STD_LOGIC_VECTOR(N-1 downto 0);
            res_ms   : out STD_LOGIC_VECTOR(N-1 downto 0));
    end component;

    component display
        Port ( clk      : in  STD_LOGIC;
               rst      : in  STD_LOGIC;
               show     : in  STD_LOGIC;                      -- Elige si mostramos la carga del teclado o el resultado
               a        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Primer factor teclado
               b        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Segundo factor teclado
               c        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Primer factor resultado
               d        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Segundo factor resultado
               selector : out STD_LOGIC_VECTOR(3 downto 0);   -- Activar dígito
               digitos  : out STD_LOGIC_VECTOR(6 downto 0);   -- Activar leds
               pd       : out STD_LOGIC); 
    end component;

begin
    -- Instanciación de debouncer
    u1: debouncer
        port map (
            col   => col,
            clk   => clk,
            rst   => rst,
            row   => row,
            value => value_signal,
            rdy   => rdy_signal
        );
    
    -- Instanciación de admin
    u2: admin
        port map (
            clk           => clk,
            rst           => rst,
            ready         => rdy_signal,  -- Conexión de debouncer
            value_in      => value_signal,  -- Conexión de debouncer
				finish        => finish_signal,  -- Conexion con activate del multi
            plot          => plot_signal,
            first_factor  => first_factor_signal,
            second_factor => second_factor_signal
        );

    -- Instanciación de multiplicador
    u3: multiplicador
        port map (
            clk   => clk,
            rst   => rst,
				activate => finish_signal,
            A     => first_factor_signal,  -- Conexión de admin
            B     => second_factor_signal,  -- Conexión de admin
            res_ls => res_ls_signal,
            res_ms => res_ms_signal
        );

    -- Instanciación de display
    u4: display
        port map (
            clk      => clk,
            rst      => rst,
            show     => plot_signal,  -- Conexión de admin para seleccionar el valor
            a        => first_factor_signal,  -- Conexión de admin
            b        => second_factor_signal,  -- Conexión de admin
            c        => res_ls_signal,  -- Conexión de multiplicador
            d        => res_ms_signal,  -- Conexión de multiplicador
            selector => selector,  -- Conectado a la salida de all_components
            digitos  => digitos,   -- Conectado a la salida de all_components
            pd       => pd         -- Conectado a la salida de all_components
        );

end Behavioral;