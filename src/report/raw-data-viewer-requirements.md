## Functional Requirements

### Export TXT (Individual File)
- **Filename Pattern**: `<EntityName>-export-<YYYY-MM-DD>.txt`
- **Encoding**: UTF-8
- **Metadata**: Includes header metadata such as Application Name, Entity, Timestamp, and Filters Summary
- **Format**: No JSON markup, uses flattened values
- **Toggle**: Provides format toggle for TSV vs Pretty.

### UI Layout
- Add an **Export TXT** button to the UI layout.

### Technology Stack Table Updates
| Technology | Description |
|------------|-------------|
| Text Export| Via native Blob / URL.createObjectURL |

### Technical Export Implementation for TXT
- Ensure tab safety and newline normalization during export.

### Acceptance Criteria for TXT Export
- [ ] Successfully exports data with specified filename pattern.
- [ ] Data is UTF-8 encoded and includes all required header metadata.
- [ ] Format toggle works correctly between TSV and Pretty.
- [ ] UI button functions correctly to trigger export.

## Implementation Order
1. Other functionality
2. CSV Export
3. **TXT Export**
4. Any subsequent features