# Story Editor Blank Creation Refactor

Overview
 Refactor the Blank creation UI to allow story editors to explicitly select existing Prompts and/or
 create new Prompts when creating a Blank. All Blank-Prompt associations will be explicit through
 StoryPrompt join records.

 User Requirements

- Replace current tags-only form with unified form including:
  - Tags input for the blank
  - Selection of existing prompts (filtered by tag match)
  - Ability to create new prompts inline (description only, inherits tags)
- On submission, automatically create Blank + new Prompts + StoryPrompt join records
- All associations must be explicit (no auto-matching)

 Implementation Plan

 Phase 1: Service Object for Atomic Creation

 Create: app/services/story_blanks_service.rb

 Service object to handle atomic creation within a transaction:

 1. Create Blank record with tags
 2. Create new Prompt records (inherit tags from blank)
 3. Find existing selected Prompts
 4. Create StoryPrompt join records linking all three
 5. Return success/failure result with errors

 Why Service Object?

- Clean transaction boundaries
- Validation across multiple models
- Easier to test
- Explicit error handling

 Phase 2: Controller Updates

 Update: app/controllers/blanks_controller.rb

- Modify create action to use StoryBlanksService service
- Update strong parameters to permit:
  - :tags
  - existing_prompt_ids: []
  - new_prompts: [:description]
- Preserve existing Turbo Stream response pattern
- Handle service errors and preserve form state

 Phase 3: New Blank Form

 Update: app/views/blanks/_form.html.erb

 Form sections:

 1. Tags Input: Text field with debounced filtering trigger
 2. Select Existing Prompts: Checklist of matching prompts (filtered by tag overlap)

- Shows prompt description and tags
- Updates dynamically based on tags input

 3. Create New Prompts: Dynamic textarea fields

- Add/remove prompt fields
- New prompts inherit blank's tags

 4. Validation: Must select/create at least one prompt

 Create: app/views/blanks/_form_errors.html.erb for error display

 Phase 4: Stimulus Controller

 Create: app/javascript/controllers/blank_form_controller.js

 Features:

- Tag-based filtering: Debounced fetch and filter prompts by tag overlap (300ms)
- Dynamic new prompt fields: Add/remove textarea fields for new prompts
- Client-side validation: Disable submit if no prompts selected/created
- Prompts caching: Fetch all prompts once, filter client-side
- Template rendering: Generate prompt checkboxes from JSON data

 Phase 5: API Endpoint

 Add to: config/routes.rb
 resources :stories do
   resources :blanks
   get 'prompts', to: 'stories#prompts'
 end

 Add to: app/controllers/stories_controller.rb
 def prompts
   @prompts = Prompt.all
   render json: @prompts.map { |p|
     { id: p.id, description: p.description, tags: p.tags }
   }
 end

 Phase 6: CSS Styling

 Update: app/assets/stylesheets/story-editor.css

 Add styles for:

- .form-section - Section dividers with border-top
- .prompts-checklist - Scrollable checkbox list with secondary background
- .prompt-checkbox - Individual prompt checkbox with hover effect
- .prompt-checkbox-tags - Tag display within prompts
- .new-prompts-list - Vertical flex for new prompt fields
- .new-prompt-field - Flex row with textarea + remove button

 Follow BEM-inspired conventions and use design tokens.

 Phase 7: Validation

 Model Level (app/models/blank.rb):

- Existing validations for tags and story_id

 Service Level (StoryBlanksService):

- Validate tags presence
- Validate at least one prompt selected or created
- Validate new prompt descriptions not blank
- Transaction rollback on any failure

 Client Level (Stimulus):

- Disable submit button when no prompts selected/created
- Show inline validation hint

 Critical Files

 New Files:

- app/services/story_blanks_service.rb - Core business logic
- app/javascript/controllers/blank_form_controller.js - Client-side interactivity
- app/views/blanks/_form_errors.html.erb - Error display

 Modified Files:

- app/controllers/blanks_controller.rb - Use service, update params
- app/views/blanks/_form.html.erb - New form structure
- app/controllers/stories_controller.rb - Add prompts endpoint
- config/routes.rb - Add prompts route
- app/assets/stylesheets/story-editor.css - Add form styles

 Implementation Order

 1. Create service object with transaction logic
 2. Update controller to use service and permit new params
 3. Add prompts JSON endpoint
 4. Refactor form HTML with new sections
 5. Create Stimulus controller for filtering and validation
 6. Add CSS styles for new components
 7. Manually test full workflow (success and error cases)

 Success Criteria

- Story editors can create blanks with explicit prompt associations
- Form filters existing prompts by tag match
- Story editors can create new prompts inline
- All creations happen atomically (transaction)
- Errors are displayed and form state is preserved
- No auto-matching behavior (all associations explicit)
