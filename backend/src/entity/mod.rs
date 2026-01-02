pub mod article;
pub mod category_briefing;
pub mod daily_briefing;
pub mod news_source;

#[allow(unused_imports)]
pub use article::Entity as Article;
pub use category_briefing::Entity as CategoryBriefing;
pub use daily_briefing::Entity as DailyBriefing;
pub use news_source::Entity as NewsSource;

