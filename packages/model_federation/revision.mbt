///|
/// Kind of a supported IFC element change between two federation snapshots.
pub(all) enum RevisionChangeKind {
  Added
  Removed
  Modified
  Ambiguous
} derive(Eq, Debug)

///|
pub extend RevisionChangeKind with Eq::{not_equal, equal}

///|
pub extend RevisionChangeKind with Debug::{to_repr}

///|
pub fn RevisionChangeKind::label(self : RevisionChangeKind) -> String {
  match self {
    Added => "added"
    Removed => "removed"
    Modified => "modified"
    Ambiguous => "ambiguous"
  }
}

///|
/// A related entity reached through IFC relationship records.
///
/// `path` alternates between entity and relationship labels, beginning at the
/// changed entity and ending at this entity. It describes structural links,
/// not geometric or engineering causality.
pub struct ImpactPath {
  entity_id : Int
  entity_type : String
  path : Array[String]
} derive(Eq, Debug)

///|
pub extend ImpactPath with Eq::{not_equal, equal}

///|
pub extend ImpactPath with Debug::{to_repr}

///|
pub fn ImpactPath::entity_id(self : ImpactPath) -> Int {
  self.entity_id
}

///|
pub fn ImpactPath::entity_type(self : ImpactPath) -> String {
  self.entity_type
}

///|
pub fn ImpactPath::path(self : ImpactPath) -> Array[String] {
  self.path.copy()
}

///|
/// A stable-identity element change and its local relation/spatial context.
pub struct FederationChange {
  model_name : String
  before_discipline : String?
  after_discipline : String?
  global_id : String
  kind : RevisionChangeKind
  before_entity_id : Int?
  after_entity_id : Int?
  before_entity_type : String?
  after_entity_type : String?
  changed_arguments : Array[Int]
  before_spatial_path : Array[String]
  after_spatial_path : Array[String]
  before_relationships : Array[String]
  after_relationships : Array[String]
  before_impact_paths : Array[ImpactPath]
  after_impact_paths : Array[ImpactPath]
  before_impact_paths_truncated : Bool
  after_impact_paths_truncated : Bool
  related_models : Array[String]
} derive(Eq, Debug)

///|
pub extend FederationChange with Eq::{not_equal, equal}

///|
pub extend FederationChange with Debug::{to_repr}

///|
pub fn FederationChange::model_name(self : FederationChange) -> String {
  self.model_name
}

///|
pub fn FederationChange::before_discipline(self : FederationChange) -> String? {
  self.before_discipline
}

///|
pub fn FederationChange::after_discipline(self : FederationChange) -> String? {
  self.after_discipline
}

///|
pub fn FederationChange::global_id(self : FederationChange) -> String {
  self.global_id
}

///|
pub fn FederationChange::kind(self : FederationChange) -> RevisionChangeKind {
  self.kind
}

///|
pub fn FederationChange::before_entity_id(self : FederationChange) -> Int? {
  self.before_entity_id
}

///|
pub fn FederationChange::after_entity_id(self : FederationChange) -> Int? {
  self.after_entity_id
}

///|
pub fn FederationChange::before_entity_type(self : FederationChange) -> String? {
  self.before_entity_type
}

///|
pub fn FederationChange::after_entity_type(self : FederationChange) -> String? {
  self.after_entity_type
}

///|
/// One-based STEP argument positions whose normalized values changed.
pub fn FederationChange::changed_arguments(
  self : FederationChange,
) -> Array[Int] {
  self.changed_arguments.copy()
}

///|
pub fn FederationChange::before_spatial_path(
  self : FederationChange,
) -> Array[String] {
  self.before_spatial_path.copy()
}

///|
pub fn FederationChange::after_spatial_path(
  self : FederationChange,
) -> Array[String] {
  self.after_spatial_path.copy()
}

///|
pub fn FederationChange::before_relationships(
  self : FederationChange,
) -> Array[String] {
  self.before_relationships.copy()
}

///|
pub fn FederationChange::after_relationships(
  self : FederationChange,
) -> Array[String] {
  self.after_relationships.copy()
}

///|
pub fn FederationChange::before_impact_paths(
  self : FederationChange,
) -> Array[ImpactPath] {
  self.before_impact_paths.copy()
}

///|
pub fn FederationChange::after_impact_paths(
  self : FederationChange,
) -> Array[ImpactPath] {
  self.after_impact_paths.copy()
}

///|
pub fn FederationChange::before_impact_paths_truncated(
  self : FederationChange,
) -> Bool {
  self.before_impact_paths_truncated
}

///|
pub fn FederationChange::after_impact_paths_truncated(
  self : FederationChange,
) -> Bool {
  self.after_impact_paths_truncated
}

///|
/// Other discipline models containing the same element GlobalId in either snapshot.
pub fn FederationChange::related_models(
  self : FederationChange,
) -> Array[String] {
  self.related_models.copy()
}

///|
/// Deterministic structural changes between two ordered federation snapshots.
pub struct FederationDiffReport {
  before_models : Array[String]
  after_models : Array[String]
  changes : Array[FederationChange]
} derive(Eq, Debug)

///|
pub extend FederationDiffReport with Eq::{not_equal, equal}

///|
pub extend FederationDiffReport with Debug::{to_repr}

///|
pub fn FederationDiffReport::before_models(
  self : FederationDiffReport,
) -> Array[String] {
  self.before_models.copy()
}

///|
pub fn FederationDiffReport::after_models(
  self : FederationDiffReport,
) -> Array[String] {
  self.after_models.copy()
}

///|
pub fn FederationDiffReport::changes(
  self : FederationDiffReport,
) -> Array[FederationChange] {
  self.changes.copy()
}

///|
pub fn FederationDiffReport::change_count(self : FederationDiffReport) -> Int {
  self.changes.length()
}

///|
pub fn FederationDiffReport::added_count(self : FederationDiffReport) -> Int {
  count_revision_changes(self.changes, Added)
}

///|
pub fn FederationDiffReport::removed_count(self : FederationDiffReport) -> Int {
  count_revision_changes(self.changes, Removed)
}

///|
pub fn FederationDiffReport::modified_count(self : FederationDiffReport) -> Int {
  count_revision_changes(self.changes, Modified)
}

///|
pub fn FederationDiffReport::ambiguous_count(
  self : FederationDiffReport,
) -> Int {
  count_revision_changes(self.changes, Ambiguous)
}

///|
fn count_revision_changes(
  changes : Array[FederationChange],
  expected : RevisionChangeKind,
) -> Int {
  let mut count = 0
  for change in changes {
    if change.kind == expected {
      count += 1
    }
  }
  count
}

///|
priv struct ModelIndex {
  source : ModelSource
  element_order : Array[String]
  elements_by_global_id : Map[String, @ifc_entities.Entity]
  duplicate_global_ids : Array[String]
  entities_by_id : Map[Int, @ifc_entities.Entity]
  relations : @relation_map.RelationMap
}

///|
fn index_model(source : ModelSource) -> ModelIndex {
  let element_order : Array[String] = []
  let elements_by_global_id : Map[String, @ifc_entities.Entity] = Map([])
  let duplicate_global_ids : Array[String] = []
  let entities_by_id : Map[Int, @ifc_entities.Entity] = Map([])
  for entity in source.entities {
    if !entities_by_id.contains(entity.id()) {
      entities_by_id[entity.id()] = entity
    }
    if entity.category() == @ifc_entities.Element {
      match entity.global_id() {
        Some(global_id) if global_id != "" =>
          match elements_by_global_id.get(global_id) {
            Some(_) =>
              if !duplicate_global_ids.contains(global_id) {
                duplicate_global_ids.push(global_id)
              }
            None => {
              element_order.push(global_id)
              elements_by_global_id[global_id] = entity
            }
          }
        _ => ()
      }
    }
  }
  {
    source,
    element_order,
    elements_by_global_id,
    duplicate_global_ids,
    entities_by_id,
    relations: @relation_map.build(source.entities),
  }
}

///|
/// Compare supported element entities by GlobalId, ignoring file-local STEP IDs.
///
/// Models are paired by their manifest `name`; elements are paired by GlobalId.
/// Direct non-element references are compared by their rooted GlobalId where
/// available, otherwise by recursively normalized entity structure. Geometry
/// equivalence is deliberately outside this structural comparison.
pub fn compare_revisions(
  before : Array[ModelSource],
  after : Array[ModelSource],
) -> FederationDiffReport {
  let before_labels : Array[String] = []
  let after_labels : Array[String] = []
  let changes : Array[FederationChange] = []
  let before_names : Map[String, Bool] = Map([])
  let related_models_by_global_id = index_related_models(before, after)
  for model in before {
    before_labels.push(revision_model_label(model))
    before_names[model.name] = true
  }
  for model in after {
    after_labels.push(revision_model_label(model))
  }
  for old_model in before {
    let old_index = index_model(old_model)
    match find_model(after, old_model.name) {
      Some(new_model) =>
        compare_matched_model(
          old_index,
          index_model(new_model),
          related_models_by_global_id,
          changes,
        )
      None =>
        compare_unmatched_model(
          old_index,
          related_models_by_global_id,
          Removed,
          changes,
        )
    }
  }
  for new_model in after {
    if !before_names.contains(new_model.name) {
      compare_unmatched_model(
        index_model(new_model),
        related_models_by_global_id,
        Added,
        changes,
      )
    }
  }
  { before_models: before_labels, after_models: after_labels, changes, }
}

///|
fn revision_model_label(model : ModelSource) -> String {
  if model.discipline == "" {
    model.name
  } else {
    model.name + " [" + model.discipline + "]"
  }
}

///|
fn find_model(models : Array[ModelSource], name : String) -> ModelSource? {
  for model in models {
    if model.name == name {
      return Some(model)
    }
  }
  None
}

///|
fn compare_matched_model(
  before : ModelIndex,
  after : ModelIndex,
  related_models_by_global_id : Map[String, Array[String]],
  changes : Array[FederationChange],
) -> Unit {
  for global_id in before.element_order {
    let old_entity = before.elements_by_global_id[global_id]
    let new_entity = after.elements_by_global_id.get(global_id)
    if before.duplicate_global_ids.contains(global_id) ||
      after.duplicate_global_ids.contains(global_id) {
      changes.push(
        make_revision_change(
          before.source.name,
          Some(before.source.discipline),
          Some(after.source.discipline),
          global_id,
          Ambiguous,
          Some(old_entity),
          new_entity,
          [],
          before,
          after,
          related_models_by_global_id,
        ),
      )
    } else {
      match new_entity {
        Some(current) => {
          let changed = changed_argument_positions(
            old_entity,
            current,
            before.entities_by_id,
            after.entities_by_id,
          )
          if old_entity.kind() != current.kind() || changed.length() > 0 {
            changes.push(
              make_revision_change(
                before.source.name,
                Some(before.source.discipline),
                Some(after.source.discipline),
                global_id,
                Modified,
                Some(old_entity),
                Some(current),
                changed,
                before,
                after,
                related_models_by_global_id,
              ),
            )
          }
        }
        None =>
          changes.push(
            make_revision_change(
              before.source.name,
              Some(before.source.discipline),
              Some(after.source.discipline),
              global_id,
              Removed,
              Some(old_entity),
              None,
              [],
              before,
              after,
              related_models_by_global_id,
            ),
          )
      }
    }
  }
  for global_id in after.element_order {
    if !before.elements_by_global_id.contains(global_id) {
      let current = after.elements_by_global_id[global_id]
      let kind = if after.duplicate_global_ids.contains(global_id) {
        Ambiguous
      } else {
        Added
      }
      changes.push(
        make_revision_change(
          after.source.name,
          Some(before.source.discipline),
          Some(after.source.discipline),
          global_id,
          kind,
          None,
          Some(current),
          [],
          before,
          after,
          related_models_by_global_id,
        ),
      )
    }
  }
}

///|
fn compare_unmatched_model(
  index : ModelIndex,
  related_models_by_global_id : Map[String, Array[String]],
  default_kind : RevisionChangeKind,
  changes : Array[FederationChange],
) -> Unit {
  for global_id in index.element_order {
    let entity = index.elements_by_global_id[global_id]
    let kind = if index.duplicate_global_ids.contains(global_id) {
      Ambiguous
    } else {
      default_kind
    }
    let before_entity = if default_kind == Removed {
      Some(entity)
    } else {
      None
    }
    let after_entity = if default_kind == Added { Some(entity) } else { None }
    let before_discipline = if default_kind == Removed {
      Some(index.source.discipline)
    } else {
      None
    }
    let after_discipline = if default_kind == Added {
      Some(index.source.discipline)
    } else {
      None
    }
    changes.push(
      make_revision_change(
        index.source.name,
        before_discipline,
        after_discipline,
        global_id,
        kind,
        before_entity,
        after_entity,
        [],
        if default_kind == Removed {
          index
        } else {
          empty_model_index()
        },
        if default_kind == Added {
          index
        } else {
          empty_model_index()
        },
        related_models_by_global_id,
      ),
    )
  }
}

///|
fn empty_model_index() -> ModelIndex {
  index_model(ModelSource::new(name="", entities=[]))
}

///|
fn make_revision_change(
  model_name : String,
  before_discipline : String?,
  after_discipline : String?,
  global_id : String,
  kind : RevisionChangeKind,
  before_entity : @ifc_entities.Entity?,
  after_entity : @ifc_entities.Entity?,
  changed_arguments : Array[Int],
  before_index : ModelIndex,
  after_index : ModelIndex,
  related_models_by_global_id : Map[String, Array[String]],
) -> FederationChange {
  let before_entity_id = match before_entity {
    Some(entity) => Some(entity.id())
    None => None
  }
  let after_entity_id = match after_entity {
    Some(entity) => Some(entity.id())
    None => None
  }
  let before_entity_type = match before_entity {
    Some(entity) => Some(entity.kind())
    None => None
  }
  let after_entity_type = match after_entity {
    Some(entity) => Some(entity.kind())
    None => None
  }
  let before_spatial_path = match before_entity_id {
    Some(id) => spatial_path(before_index.relations, id)
    None => []
  }
  let after_spatial_path = match after_entity_id {
    Some(id) => spatial_path(after_index.relations, id)
    None => []
  }
  let before_relationships = match before_entity_id {
    Some(id) => referring_relationships(before_index.relations, id)
    None => []
  }
  let after_relationships = match after_entity_id {
    Some(id) => referring_relationships(after_index.relations, id)
    None => []
  }
  let (before_impact_paths, before_impact_paths_truncated) = match
    before_entity {
    Some(entity) => trace_impact_paths(before_index.relations, entity)
    None => ([], false)
  }
  let (after_impact_paths, after_impact_paths_truncated) = match after_entity {
    Some(entity) => trace_impact_paths(after_index.relations, entity)
    None => ([], false)
  }
  let related_models : Array[String] = []
  match related_models_by_global_id.get(global_id) {
    Some(models) =>
      for name in models {
        if name != model_name {
          related_models.push(name)
        }
      }
    None => ()
  }
  {
    model_name,
    before_discipline,
    after_discipline,
    global_id,
    kind,
    before_entity_id,
    after_entity_id,
    before_entity_type,
    after_entity_type,
    changed_arguments,
    before_spatial_path,
    after_spatial_path,
    before_relationships,
    after_relationships,
    before_impact_paths,
    after_impact_paths,
    before_impact_paths_truncated,
    after_impact_paths_truncated,
    related_models,
  }
}

///|
fn index_related_models(
  before : Array[ModelSource],
  after : Array[ModelSource],
) -> Map[String, Array[String]] {
  let index : Map[String, Array[String]] = Map([])
  for source in before {
    index_model_global_ids(source, index)
  }
  for source in after {
    index_model_global_ids(source, index)
  }
  index
}

///|
fn index_model_global_ids(
  source : ModelSource,
  index : Map[String, Array[String]],
) -> Unit {
  for entity in source.entities {
    if entity.category() == @ifc_entities.Element {
      match entity.global_id() {
        Some(global_id) if global_id != "" =>
          match index.get(global_id) {
            Some(models) =>
              if !models.contains(source.name) {
                models.push(source.name)
              }
            None => index[global_id] = [source.name]
          }
        _ => ()
      }
    }
  }
}

///|
fn spatial_path(
  relations : @relation_map.RelationMap,
  entity_id : Int,
) -> Array[String] {
  let path : Array[String] = []
  let seen : Map[Int, Bool] = Map([])
  let mut parent = relations.parent_of(entity_id)
  for _ in 0..<relations.entities().length() {
    match parent {
      Some(id) if !seen.contains(id) => {
        seen[id] = true
        match relations.entity_by_id(id) {
          Some(entity) => {
            path.push(entity_label(entity))
            parent = relations.parent_of(id)
          }
          None => parent = None
        }
      }
      _ => parent = None
    }
  }
  path
}

///|
fn referring_relationships(
  relations : @relation_map.RelationMap,
  entity_id : Int,
) -> Array[String] {
  let impacts : Array[String] = []
  for source_id in relations.incoming_references(entity_id) {
    match relations.entity_by_id(source_id) {
      Some(entity) if entity.category() == @ifc_entities.Relationship =>
        impacts.push(entity_label(entity))
      _ => ()
    }
  }
  impacts
}

///|
fn entity_label(entity : @ifc_entities.Entity) -> String {
  match entity.global_id() {
    Some(global_id) if global_id != "" =>
      entity.kind() + "#" + entity.id().to_string() + " [" + global_id + "]"
    _ => entity.kind() + "#" + entity.id().to_string()
  }
}

///|
priv struct ImpactSearchNode {
  entity_id : Int
  path : Array[String]
}

///|
/// Traverse relationship records as undirected structural associations. The
/// stable source order and a visited set make the first path deterministic and
/// prevent cycles; the cap keeps a single change from expanding without bound.
fn trace_impact_paths(
  relations : @relation_map.RelationMap,
  start : @ifc_entities.Entity,
) -> (Array[ImpactPath], Bool) {
  let paths : Array[ImpactPath] = []
  let seen : Map[Int, Bool] = Map([])
  let queue : Array[ImpactSearchNode] = [
    { entity_id: start.id(), path: [entity_label(start)], },
  ]
  let path_limit = 100
  let mut cursor = 0
  let mut truncated = false
  seen[start.id()] = true
  while cursor < queue.length() && !truncated {
    let current = queue[cursor]
    cursor += 1
    for relation_id in relations.incoming_references(current.entity_id) {
      if !truncated {
        match relations.entity_by_id(relation_id) {
          Some(relation) if relation.category() == @ifc_entities.Relationship =>
            for related_id in relation.references() {
              if !truncated &&
                related_id != current.entity_id &&
                !seen.contains(related_id) {
                match relations.entity_by_id(related_id) {
                  Some(target) if target.category() == @ifc_entities.Element ||
                    target.category() == @ifc_entities.Spatial =>
                    if paths.length() >= path_limit {
                      truncated = true
                    } else {
                      seen[related_id] = true
                      let path = current.path.copy()
                      path.push(entity_label(relation))
                      path.push(entity_label(target))
                      paths.push({
                        entity_id: target.id(),
                        entity_type: target.kind(),
                        path,
                      })
                      queue.push({ entity_id: target.id(), path, })
                    }
                  _ => ()
                }
              }
            }
          _ => ()
        }
      }
    }
  }
  (paths, truncated)
}

///|
fn changed_argument_positions(
  before : @ifc_entities.Entity,
  after : @ifc_entities.Entity,
  before_entities : Map[Int, @ifc_entities.Entity],
  after_entities : Map[Int, @ifc_entities.Entity],
) -> Array[Int] {
  let before_args = before.args()
  let after_args = after.args()
  let length = if before_args.length() > after_args.length() {
    before_args.length()
  } else {
    after_args.length()
  }
  let changed : Array[Int] = []
  for index in 0..<length {
    let same = match (before_args.get(index), after_args.get(index)) {
      (Some(left), Some(right)) =>
        stable_value_equal(
          left,
          right,
          before_entities,
          after_entities,
          Map([]),
        )
      (None, None) => true
      _ => false
    }
    if !same {
      changed.push(index + 1)
    }
  }
  changed
}

///|
fn stable_value_equal(
  before : @step_text.Value,
  after : @step_text.Value,
  before_entities : Map[Int, @ifc_entities.Entity],
  after_entities : Map[Int, @ifc_entities.Entity],
  compared_pairs : Map[String, Bool],
) -> Bool {
  match (before, after) {
    (@step_text.Integer(left), @step_text.Integer(right)) => left == right
    (@step_text.Real(left), @step_text.Real(right)) => left == right
    (@step_text.String(left), @step_text.String(right)) => left == right
    (@step_text.Boolean(left), @step_text.Boolean(right)) => left == right
    (@step_text.Enum(left), @step_text.Enum(right)) => left == right
    (@step_text.Omitted, @step_text.Omitted) => true
    (@step_text.Derived, @step_text.Derived) => true
    (@step_text.Reference(left), @step_text.Reference(right)) =>
      match (before_entities.get(left), after_entities.get(right)) {
        (Some(old_entity), Some(new_entity)) =>
          stable_entity_equal(
            old_entity, new_entity, before_entities, after_entities, compared_pairs,
          )
        _ => false
      }
    (@step_text.Aggregate(left), @step_text.Aggregate(right)) =>
      if left.length() != right.length() {
        false
      } else {
        let mut same = true
        for index in 0..<left.length() {
          if !stable_value_equal(
              left[index],
              right[index],
              before_entities,
              after_entities,
              compared_pairs,
            ) {
            same = false
          }
        }
        same
      }
    _ => false
  }
}

///|
fn stable_entity_equal(
  before : @ifc_entities.Entity,
  after : @ifc_entities.Entity,
  before_entities : Map[Int, @ifc_entities.Entity],
  after_entities : Map[Int, @ifc_entities.Entity],
  compared_pairs : Map[String, Bool],
) -> Bool {
  if before.kind() != after.kind() {
    return false
  }
  match (before.global_id(), after.global_id()) {
    (Some(left), Some(right)) if left != "" || right != "" => left == right
    (Some(left), None) if left != "" => false
    (None, Some(right)) if right != "" => false
    _ => {
      let pair = before.id().to_string() + ":" + after.id().to_string()
      if compared_pairs.contains(pair) {
        return true
      }
      compared_pairs[pair] = true
      let left = before.args()
      let right = after.args()
      if left.length() != right.length() {
        return false
      }
      let mut same = true
      for index in 0..<left.length() {
        if !stable_value_equal(
            left[index],
            right[index],
            before_entities,
            after_entities,
            compared_pairs,
          ) {
          same = false
        }
      }
      same
    }
  }
}
