#![allow(unused_variables, unused_mut, dead_code)]
use aoc_runner_derive::{aoc, aoc_generator};

#[aoc_generator(day2)]
pub fn parse_input(input: &str) -> Vec<(u32, u32, u32)> {
    input.lines().map(parse_line).collect()
}

fn parse_line(line: &str) -> (u32, u32, u32) {
    let (_prefix, pulls) = line
        .split_once(": ")
        .expect("all lines include a `Game:` prefix");

    let mut counts = (0, 0, 0);

    for pull in pulls.split("; ") {
        for color in pull.split(", ") {
            let (count, color) = color.split_once(' ').unwrap();
            let count = count.parse().expect("all numbers in input should be valid");
            match color {
                "red" => counts.0 = counts.0.max(count),
                "green" => counts.1 = counts.1.max(count),
                "blue" => counts.2 = counts.2.max(count),
                _ => unreachable!(),
            };
        }
    }
    counts
}

#[aoc(day2, part1)]
fn part1(input: &[(u32, u32, u32)]) -> usize {
    input
        .iter()
        .enumerate()
        .filter(|(_idx, &(r, g, b))| r <= 12 && g <= 13 && b <= 14)
        .map(|el| el.0 + 1)
        .sum()
}

#[aoc(day2, part2)]
fn part2(input: &[(u32, u32, u32)]) -> u32 {
    input.iter().map(|&(r, g, b)| r * g * b).sum()
}
