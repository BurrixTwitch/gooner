#!/usr/bin/env python3
"""gooner - terminal gaming session tracker"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.text import Text
    from rich import box
    from rich.columns import Columns
    from rich.rule import Rule
    HAS_RICH = True
except ImportError:
    HAS_RICH = False

DATA_DIR = Path.home() / ".gooner"
DATA_FILE = DATA_DIR / "sessions.json"

console = Console() if HAS_RICH else None

W = "[green]W[/green]" if HAS_RICH else "W"
L = "[red]L[/red]" if HAS_RICH else "L"
D = "[yellow]D[/yellow]" if HAS_RICH else "D"


# ── data helpers ────────────────────────────────────────────────────────────

def load_data():
    DATA_DIR.mkdir(exist_ok=True)
    if not DATA_FILE.exists():
        return {"sessions": [], "active": None}
    with open(DATA_FILE) as f:
        return json.load(f)


def save_data(data):
    DATA_DIR.mkdir(exist_ok=True)
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2, default=str)


def fmt_duration(seconds: float) -> str:
    seconds = int(seconds)
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h}h {m}m"
    if m:
        return f"{m}m {s}s"
    return f"{s}s"


def result_label(result: str) -> str:
    return {"win": W, "loss": L, "draw": D, "": "-"}.get(result, result)


def current_streak(sessions, game=None) -> tuple[int, str]:
    relevant = [s for s in reversed(sessions) if s.get("result") and (game is None or s["game"].lower() == game.lower())]
    if not relevant:
        return 0, ""
    streak_result = relevant[0]["result"]
    count = 0
    for s in relevant:
        if s["result"] == streak_result:
            count += 1
        else:
            break
    return count, streak_result


def game_stats(sessions, game):
    gs = [s for s in sessions if s["game"].lower() == game.lower()]
    wins = sum(1 for s in gs if s.get("result") == "win")
    losses = sum(1 for s in gs if s.get("result") == "loss")
    draws = sum(1 for s in gs if s.get("result") == "draw")
    total_time = sum(s.get("duration_seconds", 0) for s in gs)
    return {"sessions": len(gs), "wins": wins, "losses": losses, "draws": draws, "total_time": total_time}


# ── commands ────────────────────────────────────────────────────────────────

def cmd_start(args):
    data = load_data()
    if data["active"]:
        active_game = data["active"]["game"]
        started = datetime.fromisoformat(data["active"]["started"])
        elapsed = fmt_duration((datetime.now() - started).total_seconds())
        _print(f"[yellow]Already in a session:[/yellow] [bold]{active_game}[/bold] (running for {elapsed})")
        _print("Stop it first with: [bold]gooner stop[/bold]")
        return

    game = " ".join(args.game)
    data["active"] = {
        "game": game,
        "started": datetime.now().isoformat(),
    }
    save_data(data)
    _print(f"[green]Session started![/green] Playing [bold cyan]{game}[/bold cyan]  •  gl hf :)")


def cmd_stop(args):
    data = load_data()
    if not data["active"]:
        _print("[yellow]No active session.[/yellow] Start one with: [bold]gooner start <game>[/bold]")
        return

    game = data["active"]["game"]
    started = datetime.fromisoformat(data["active"]["started"])
    ended = datetime.now()
    duration = (ended - started).total_seconds()

    result = (args.result or "").lower()
    if result and result not in ("win", "loss", "draw", "w", "l", "d"):
        _print("[red]Result must be: win, loss, or draw (or w/l/d)[/red]")
        return
    result = {"w": "win", "l": "loss", "d": "draw"}.get(result, result)

    session = {
        "game": game,
        "started": started.isoformat(),
        "ended": ended.isoformat(),
        "duration_seconds": duration,
        "result": result,
        "note": " ".join(args.note) if args.note else "",
    }
    data["sessions"].append(session)
    data["active"] = None
    save_data(data)

    res_str = f"  Result: {result_label(result)}" if result else ""
    _print(f"[green]Session saved![/green] [bold cyan]{game}[/bold cyan]  •  {fmt_duration(duration)}{res_str}")


def cmd_status(args):
    data = load_data()
    if not data["active"]:
        _print("[dim]No active session.[/dim]")
        return
    game = data["active"]["game"]
    started = datetime.fromisoformat(data["active"]["started"])
    elapsed = (datetime.now() - started).total_seconds()
    _print(f"[green]●[/green] Playing [bold cyan]{game}[/bold cyan]  •  {fmt_duration(elapsed)}")


def cmd_stats(args):
    data = load_data()
    sessions = data["sessions"]

    if not sessions:
        _print("[dim]No sessions recorded yet. Start with:[/dim] [bold]gooner start <game>[/bold]")
        return

    filter_game = " ".join(args.game) if args.game else None

    if filter_game:
        _stats_for_game(sessions, filter_game)
    else:
        _stats_all(sessions)


def _stats_for_game(sessions, game):
    gs = [s for s in sessions if s["game"].lower() == game.lower()]
    if not gs:
        _print(f"[yellow]No sessions found for:[/yellow] {game}")
        return

    st = game_stats(sessions, game)
    played = st["sessions"]
    total = st["wins"] + st["losses"] + st["draws"]
    wl = f"{st['wins']}/{st['losses']}" + (f"/{st['draws']}" if st["draws"] else "")
    winrate = f"{st['wins']/total*100:.0f}%" if total else "N/A"
    avg = fmt_duration(st["total_time"] / played) if played else "N/A"
    streak_n, streak_type = current_streak(sessions, game)
    streak_str = f"{streak_n}x {result_label(streak_type)}" if streak_n else "none"

    if HAS_RICH:
        table = Table(box=box.SIMPLE_HEAVY, show_header=False, min_width=40)
        table.add_column(style="dim", width=18)
        table.add_column(style="bold")
        table.add_row("Sessions", str(played))
        table.add_row("W / L" + (" / D" if st["draws"] else ""), wl)
        table.add_row("Win rate", winrate)
        table.add_row("Total time", fmt_duration(st["total_time"]))
        table.add_row("Avg session", avg)
        table.add_row("Streak", streak_str)
        console.print(Panel(table, title=f"[bold cyan]{gs[0]['game']}[/bold cyan]", border_style="cyan"))
    else:
        print(f"\n=== {gs[0]['game']} ===")
        print(f"Sessions:   {played}")
        print(f"W/L:        {wl}")
        print(f"Win rate:   {winrate}")
        print(f"Total time: {fmt_duration(st['total_time'])}")
        print(f"Avg:        {avg}")
        print(f"Streak:     {streak_str}\n")


def _stats_all(sessions):
    games = {}
    for s in sessions:
        g = s["game"]
        if g not in games:
            games[g] = []
        games[g].append(s)

    total_time = sum(s.get("duration_seconds", 0) for s in sessions)
    streak_n, streak_type = current_streak(sessions)

    if HAS_RICH:
        # Header panel
        header_lines = [
            f"[bold]Total sessions:[/bold] {len(sessions)}    "
            f"[bold]Total playtime:[/bold] {fmt_duration(total_time)}    "
            f"[bold]Games tracked:[/bold] {len(games)}"
        ]
        if streak_n:
            header_lines.append(f"[bold]Current streak:[/bold] {streak_n}x {result_label(streak_type)}")
        console.print(Panel("\n".join(header_lines), title="[bold magenta]gooner stats[/bold magenta]", border_style="magenta"))

        table = Table(box=box.SIMPLE_HEAVY, show_edge=True, header_style="bold")
        table.add_column("Game", style="cyan bold", min_width=20)
        table.add_column("Sessions", justify="right")
        table.add_column("W/L/D", justify="center")
        table.add_column("Win %", justify="right")
        table.add_column("Total time", justify="right")
        table.add_column("Avg session", justify="right")

        sorted_games = sorted(games.items(), key=lambda x: sum(s.get("duration_seconds", 0) for s in x[1]), reverse=True)
        for gname, gsessions in sorted_games:
            st = game_stats(sessions, gname)
            total_rated = st["wins"] + st["losses"] + st["draws"]
            winrate = f"{st['wins']/total_rated*100:.0f}%" if total_rated else "—"
            wld = f"[green]{st['wins']}[/green]/[red]{st['losses']}[/red]/[yellow]{st['draws']}[/yellow]"
            avg = fmt_duration(st["total_time"] / st["sessions"]) if st["sessions"] else "—"
            table.add_row(gname, str(st["sessions"]), wld, winrate, fmt_duration(st["total_time"]), avg)

        console.print(table)
    else:
        print(f"\n=== gooner stats ===")
        print(f"Sessions: {len(sessions)}  |  Playtime: {fmt_duration(total_time)}  |  Games: {len(games)}")
        print(f"{'Game':<24} {'Sess':>5} {'W/L/D':>9} {'Win%':>6} {'Time':>10} {'Avg':>8}")
        print("-" * 70)
        for gname, gsessions in sorted(games.items(), key=lambda x: len(x[1]), reverse=True):
            st = game_stats(sessions, gname)
            total_rated = st["wins"] + st["losses"] + st["draws"]
            winrate = f"{st['wins']/total_rated*100:.0f}%" if total_rated else "—"
            wld = f"{st['wins']}/{st['losses']}/{st['draws']}"
            avg = fmt_duration(st["total_time"] / st["sessions"]) if st["sessions"] else "—"
            print(f"{gname:<24} {st['sessions']:>5} {wld:>9} {winrate:>6} {fmt_duration(st['total_time']):>10} {avg:>8}")
        print()


def cmd_history(args):
    data = load_data()
    sessions = data["sessions"]
    n = args.n or 15
    game_filter = " ".join(args.game) if args.game else None

    filtered = [s for s in sessions if not game_filter or s["game"].lower() == game_filter.lower()]
    recent = list(reversed(filtered))[:n]

    if not recent:
        _print("[dim]No sessions found.[/dim]")
        return

    if HAS_RICH:
        table = Table(box=box.SIMPLE_HEAVY, show_edge=True, header_style="bold")
        table.add_column("#", justify="right", style="dim", width=4)
        table.add_column("Game", style="cyan", min_width=20)
        table.add_column("Result", justify="center", width=6)
        table.add_column("Duration", justify="right")
        table.add_column("Date", style="dim")
        table.add_column("Note", style="italic dim", max_width=35)

        for i, s in enumerate(recent, 1):
            started = datetime.fromisoformat(s["started"])
            date_str = started.strftime("%b %d  %H:%M")
            table.add_row(
                str(i),
                s["game"],
                result_label(s.get("result", "")),
                fmt_duration(s.get("duration_seconds", 0)),
                date_str,
                s.get("note", ""),
            )
        title = f"[bold]Recent sessions[/bold]" + (f" — {game_filter}" if game_filter else "")
        console.print(Panel(table, title=title, border_style="blue"))
    else:
        print(f"\n{'#':>3}  {'Game':<22} {'Result':>6} {'Time':>8}  {'Date':<16}  Note")
        print("-" * 75)
        for i, s in enumerate(recent, 1):
            started = datetime.fromisoformat(s["started"])
            date_str = started.strftime("%b %d %H:%M")
            res = s.get("result", "-") or "-"
            note = s.get("note", "")[:30]
            print(f"{i:>3}  {s['game']:<22} {res:>6} {fmt_duration(s.get('duration_seconds',0)):>8}  {date_str:<16}  {note}")
        print()


def cmd_games(args):
    data = load_data()
    sessions = data["sessions"]
    if not sessions:
        _print("[dim]No games tracked yet.[/dim]")
        return
    games = sorted(set(s["game"] for s in sessions))
    if HAS_RICH:
        items = [Text(f"  {g}", style="cyan bold") for g in games]
        console.print(Panel("\n".join(str(i) for i in items), title="[bold]Your games[/bold]", border_style="cyan"))
    else:
        print("\nGames:")
        for g in games:
            print(f"  {g}")
        print()


def cmd_delete(args):
    data = load_data()
    sessions = data["sessions"]
    if not sessions:
        _print("[dim]Nothing to delete.[/dim]")
        return
    idx = args.n - 1
    if idx < 0 or idx >= len(sessions):
        _print(f"[red]No session #{args.n}[/red]")
        return
    removed = sessions.pop(idx)
    save_data(data)
    _print(f"[yellow]Deleted:[/yellow] {removed['game']} ({fmt_duration(removed.get('duration_seconds', 0))})")


def _print(msg):
    if HAS_RICH:
        console.print(msg)
    else:
        # strip rich markup naively
        import re
        print(re.sub(r"\[/?[^\]]+\]", "", msg))


# ── CLI setup ────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        prog="gooner",
        description="gaming session tracker for the terminally online",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  gooner start Valorant
  gooner stop --result win --note "clutched the 1v3"
  gooner stop -r loss
  gooner status
  gooner stats
  gooner stats Valorant
  gooner history
  gooner history --game Valorant -n 5
  gooner games
        """,
    )
    sub = parser.add_subparsers(dest="command")

    # start
    p_start = sub.add_parser("start", help="start a gaming session")
    p_start.add_argument("game", nargs="+", help="game name")

    # stop
    p_stop = sub.add_parser("stop", help="stop the current session")
    p_stop.add_argument("-r", "--result", metavar="RESULT", help="win / loss / draw  (or w/l/d)")
    p_stop.add_argument("-n", "--note", nargs="*", help="short note about the session")

    # status
    sub.add_parser("status", help="show active session")

    # stats
    p_stats = sub.add_parser("stats", help="show stats (all games, or one game)")
    p_stats.add_argument("game", nargs="*", help="game name (omit for all)")

    # history
    p_hist = sub.add_parser("history", help="show recent sessions")
    p_hist.add_argument("-n", type=int, default=15, help="number of sessions (default 15)")
    p_hist.add_argument("--game", nargs="*", help="filter by game")

    # games
    sub.add_parser("games", help="list all tracked games")

    # delete
    p_del = sub.add_parser("delete", help="delete a session by its history index")
    p_del.add_argument("n", type=int, help="session number from history")

    args = parser.parse_args()

    dispatch = {
        "start": cmd_start,
        "stop": cmd_stop,
        "status": cmd_status,
        "stats": cmd_stats,
        "history": cmd_history,
        "games": cmd_games,
        "delete": cmd_delete,
    }

    if args.command in dispatch:
        dispatch[args.command](args)
    else:
        # no subcommand: show status if active, else help
        data = load_data()
        if data.get("active"):
            cmd_status(args)
        else:
            parser.print_help()


if __name__ == "__main__":
    main()
