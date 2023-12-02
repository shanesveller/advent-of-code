use aoc_runner_derive::{aoc, aoc_generator};

#[aoc_generator(day1, part1)]
pub fn parse_input(input: &str) -> Vec<u32> {
    input
        .lines()
        .map(|line| {
            let mut digits = line
                .chars()
                .filter(char::is_ascii_digit)
                .filter_map(|c| c.to_digit(10));

            let n = digits.next().expect("should have at least one digit");
            digits.last().unwrap_or(n) + n * 10
        })
        .collect()
}

#[aoc(day1, part1)]
pub fn part1(input: &[u32]) -> u32 {
    input.iter().sum()
}
