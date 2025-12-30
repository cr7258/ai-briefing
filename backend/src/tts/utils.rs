use pulldown_cmark::{Event, Parser, Tag, TagEnd};

/// Convert markdown to plain text suitable for TTS
pub fn markdown_to_plain_text(markdown: &str) -> String {
    let parser = Parser::new(markdown);
    let mut text = String::new();
    let mut in_link = false;

    for event in parser {
        match event {
            Event::Text(t) => {
                if !in_link {
                    text.push_str(&t);
                }
            }
            Event::SoftBreak | Event::HardBreak => {
                text.push(' ');
            }
            Event::Start(Tag::Link { .. }) => {
                in_link = true;
            }
            Event::End(TagEnd::Link) => {
                in_link = false;
            }
            Event::Start(Tag::Paragraph) => {
                if !text.is_empty() {
                    text.push_str("\n\n");
                }
            }
            Event::Start(Tag::Heading { .. }) => {
                if !text.is_empty() {
                    text.push_str("\n\n");
                }
            }
            Event::End(TagEnd::Heading(_)) => {
                text.push_str("。\n");
            }
            Event::Start(Tag::Item) => {
                text.push('\n');
            }
            _ => {}
        }
    }

    // Clean up multiple spaces/newlines
    let mut result = String::new();
    let mut prev_char = ' ';
    for c in text.chars() {
        if c.is_whitespace() {
            if !prev_char.is_whitespace() {
                result.push(' ');
            }
        } else {
            result.push(c);
        }
        prev_char = c;
    }

    result.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_markdown_to_plain_text() {
        let markdown = "## 今日要闻\n\n这是**重要**新闻。\n\n[阅读原文](https://example.com)";
        let plain = markdown_to_plain_text(markdown);
        assert!(plain.contains("今日要闻"));
        assert!(plain.contains("重要"));
        assert!(!plain.contains("https://"));
    }
}

