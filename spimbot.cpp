#include "spimbot.h"
#include <random>

// Vien's
std::pair<int, int> get_best_corn(int x, int y, char **k)
{
    
}

int euclidean(int x0, int y0, int x1, int y1)
{
    int dx = x1 - x0;
    int dy = y1 - y0;
    dx = dx * dx;
    dy = dy * dy;
    int d = dx + dy;
    d = sqrt(d);
    return d;
}

int sqrt(int n)
{
    int x = n;
    int i = 0;
    int half_n = n / 2;
    while (i < half_n)
    {
        int temp = n / x;
        temp = temp + x;
        x = temp / 2;
        i = i + 1;
    }
    return x;
}

int euclidean_time(int d)
{
    int MAX_VELOCITY = 10;
    int t = d / MAX_VELOCITY;
    return t;
}

int bonk_handler(int dir, int **m)
{
    int rand_angle = rng(180);
    rand_angle = rand_angle + 180;
    rand_angle = dir + rand_angle;
    return rand_angle;
}

int rng(int upper)
{
    /* In MIPS, do:
    li $v0, 40  # Random seed
    li $a0, 0   # RNG ID = 0
    syscall

    li $v0, 42  # Random int range
    li $a0, 0   # RNG ID = 0
    li $a1, 180 # Generates random int 0 <= x < 180
    syscall

    # Random number is now in $a0
    */
   int x = rand() % 180;
   return x;
}

/* Return value legends: 0 = "should not solve"
                         1 = "can solve within eta"
                         2 = "can solve within eta + tol"
*/
int should_solve_puzzle(int eta, int ets, int tol)
{
    int time_diff = ets - eta;
    int should_solve = 0;
    if (time_diff < tol)
        should_solve = 2;
    else if (time_diff < 0)
        should_solve = 1;
    return should_solve;
}

int compute_solve_time(int r, int c, int d)
{
    // Placeholder code, not the actual formula
    int solve_time = r * c;
    solve_time = solve_time / d;
    return solve_time;
}

bool should_pickup(int x, int y, char **k)
{
    int num_k = k[y][x];
    bool should_pickup = true;
    if (num_k == 0)
        should_pickup = false;
    return should_pickup;
}

// Tino's
int compute_direction(int x0, int y0, int x1, int y1)
{
    return sb_arctan(x1 - x0, y1 - y0);
}

void build_silo(int x, int y)
{
    if (num_corn < 10) return;

    MiniBot_Info info = get_minibot_info();

    if (info.minibots[0].x != x || info.minibots[0].y != y) {
        select_minibot_by_id(info[0].ID);
        set_target_tile(x, y);

        build_silo(x, y);
    } else if (info.minibots[1].x != x || info.minibots[1].y != y) {
        select_minibot_by_id(info.minibots[1].ID);
        set_target_tile(x, y);

        build_silo(x, y);
    } else if (info.minibots[2].x != x || info.minibots[2].y != y) {
        select_minibot_by_id(info.minibots[2].ID);
        set_target_tile(x, y);

        build_silo(x, y);
    } else {
        build_silo_command(x, y);
    }
}

int num_corn;
int num_bots;
void build_silo_command(int x, int y);
void set_target_tile(int x, int y);
void select_minibot_by_id(int id);
typedef struct MiniBot {
    int ID;
    char type;
    int x;
    int y;
    int kernels;
} MiniBot;
typedef struct MiniBot_Info {
    int num_minibots;
    struct MiniBot minibots[num_bots];
} MiniBot_Info;
MiniBot_Info get_minibot_info();
int bot_x();
int bot_y();
int sb_arctan(int x, int y);
void set_angle(int angle);
void travel_to_point(int x, int y)
{
    int x0 = bot_x();
    int y0 = bot_y();

    if (x0 == x && y0 == y) return;

    int dx = x - x0;
    int dy = y - y0;

    int angle = sb_arctan(dx, dy);
    set_angle(angle);

    travel_to_point(x, y);
}

void send_mb_to_point(int x, int y, int bot)
{
    MiniBot_Info info = get_minibot_info();

    select_minibot_by_id(info[bot].ID);
    set_target_tile(x,y);
}

std::pair<int, int> compute_silo_xy()
{
}
