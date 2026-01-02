use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "category_briefings")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub briefing_id: Option<Uuid>,
    pub category: String,
    #[sea_orm(column_type = "Text")]
    pub summary: String,
    pub audio_url: Option<String>,
    pub audio_duration: Option<i32>,
    pub article_count: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::daily_briefing::Entity",
        from = "Column::BriefingId",
        to = "super::daily_briefing::Column::Id"
    )]
    DailyBriefing,
}

impl Related<super::daily_briefing::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::DailyBriefing.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}

