import React, { useState } from 'react';
import * as Reactodia from '@reactodia/workspace';
import { blockingDefaultLayout } from '@reactodia/workspace/layout-sync';
import * as N3 from 'n3';


export function ReactodiaGraph({ useCaseSlug, token }) {
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState(null);

  
  // Create a workspace using the synchronous layout
  const [workspace] = React.useState(() =>
    Reactodia.createWorkspace({
      defaultLayout: blockingDefaultLayout
    })
  );

  // Reactodia loads data after the workspace has mounted
  const { onMount } = Reactodia.useLoadedWorkspace(
    async ({ context, signal }) => {
      const { model, view, performLayout } = context;

      setLoading(true);
      setError(null);

      try {
        if (!useCaseSlug) {
          throw new Error('No use case selected');
        }

        if (!token) {
          throw new Error('Please sign in to load the ontology');
        }

        const url =
          '/api/v1/knowledge-maintenance/ontology/export' +
          '?format=ttl&useCase=' +
          encodeURIComponent(useCaseSlug);

        const response = await fetch(url, {
          signal,
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          const details = await response.text();
          throw new Error(
            `API error ${response.status}: ${details.slice(0, 200)}`
          );
        }

        // Read ontology data
        const rawResponse = await response.text();
        let ttl = rawResponse;

        // Handle JSON-encoded Turtle from the stub backend
        if (rawResponse.trim().startsWith('"')) {
          const decoded = JSON.parse(rawResponse);

          if (typeof decoded !== 'string') {
            throw new Error('Invalid ontology response format');
          }

          ttl = decoded;
        }

        if (!ttl.trim()) {
          throw new Error('Empty ontology response');
        }

        // Convert Turtle text into RDF triples
        const quads = new N3.Parser().parse(ttl);
        console.log('REACTODIA CHECK 1 - RDF triples:', quads.length);

        if (quads.length === 0) {
          throw new Error('No RDF data found in ontology');
        }

        // Create Reactodia's RDF data provider
        const dataProvider = new Reactodia.RdfDataProvider({
          acceptBlankNodes: false,
        });

        dataProvider.addGraph(quads);

        // Create a diagram through the MODEL, not workspace
        await model.createNewDiagram({
          dataProvider,
          signal,
        });

        // Find OWL classes in the ontology
        const owlClass =
          'http://www.w3.org/2002/07/owl#Class';

        const classes = await dataProvider.lookup({
          elementTypeId: owlClass,
        });

        if (classes.length === 0) {
          throw new Error('No OWL classes found in ontology');
        }
        console.log('REACTODIA CHECK 2 - OWL classes:', classes.length);

        // Add ontology classes as graph nodes
        for (const { element } of classes) {
          model.createElement(element.id);
        }

        // Load the nodes and their relationships
        await model.requestData();

        // Automatically arrange graph elements        
        await performLayout({
          signal,
          zoomToFit: true,
          animate: false
        });

        console.log('REACTODIA CHECK 3 - Layout completed');

          requestAnimationFrame(() => {
            requestAnimationFrame(() => {
              if (signal.aborted) return;

              const canvas = view.findAnyCanvas();

              if (canvas) {
                canvas.zoomToFit();
              }
            });
          });

        if (!signal.aborted) {
          setLoading(false);
        }
      } catch (err) {
        if (signal.aborted) return;

        console.error('Failed to load graph data:', err);
        setError(
          err instanceof Error
            ? err.message
            : 'Failed to load knowledge graph'
        );
        setLoading(false);
      }
    },
    [useCaseSlug, token]
  );

  return (
    <div style={styles.root}>
      <Reactodia.WorkspaceProvider
        workspace={workspace}
        onMount={onMount}
      >
        <Reactodia.DefaultWorkspace />
      </Reactodia.WorkspaceProvider>

      {loading && (
        <div style={styles.overlay}>
          <div style={styles.spinner} />
          <p>Loading knowledge graph...</p>
        </div>
      )}

      {error && (
        <div style={styles.overlay}>
          <p style={styles.errorText}>{error}</p>
          <p style={styles.hint}>
            Check the connection and use the refresh
            button above to try again.
          </p>
        </div>
      )}
    </div>
  );
}

const styles = {
  root: {
    position: 'relative',
    width: '100%',
    height: '100%',
    minHeight: '500px',
    overflow: 'hidden',
  },
  overlay: {
    position: 'absolute',
    inset: 0,
    zIndex: 10,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '12px',
    padding: '24px',
    textAlign: 'center',
    background: '#ffffff',
  },
  spinner: {
    width: '36px',
    height: '36px',
    border: '3px solid #e5e5e5',
    borderTopColor: '#087E42',
    borderRadius: '50%',
    animation: 'reactodia-spin 0.8s linear infinite',
  },
  errorText: {
    color: '#dc2626',
    fontSize: '14px',
    maxWidth: '480px',
    overflowWrap: 'anywhere',
  },
  hint: {
    color: '#6b7280',
    fontSize: '13px',
  },
};
